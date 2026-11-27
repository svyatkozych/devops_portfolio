#include <algorithm>
#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <string>
#include <string_view>
#include <unordered_map>
#include <utility>
#include <vector>

namespace {

constexpr std::size_t npos = std::string_view::npos;

struct Entry {
    long count = 0;
    std::size_t order = 0;  // first-seen order, used to break ties like Python's Counter
};
using Counter = std::unordered_map<std::string, Entry>;

struct Record {
    std::string_view ip;
    std::string_view path;
    int status = 0;
};

bool is_digit(char c) { return c >= '0' && c <= '9'; }

std::string_view trim(std::string_view s) {
    const char* ws = " \t\r\n\v\f";
    auto b = s.find_first_not_of(ws);
    if (b == npos) return {};
    auto e = s.find_last_not_of(ws);
    return s.substr(b, e - b + 1);
}

// End of the non-empty token that starts at `from`, or npos.
std::size_t token_end(std::string_view s, std::size_t from) {
    auto e = s.find(' ', from);
    return (e == npos || e == from) ? npos : e;
}

// Format: IP IDENT USER [TIME] "METHOD PATH ..." STATUS SIZE ...
bool parse_line(std::string_view s, Record& r) {
    std::size_t e1 = token_end(s, 0);
    if (e1 == npos) return false;
    std::size_t e2 = token_end(s, e1 + 1);
    if (e2 == npos) return false;
    std::size_t e3 = token_end(s, e2 + 1);
    if (e3 == npos) return false;

    std::size_t i = e3 + 1;
    if (i >= s.size() || s[i] != '[') return false;
    std::size_t close = s.find(']', i + 1);
    if (close == npos) return false;

    i = close + 1;
    if (i + 1 >= s.size() || s[i] != ' ' || s[i + 1] != '"') return false;
    i += 2;

    std::size_t em = token_end(s, i);
    if (em == npos) return false;
    std::size_t ps = em + 1;
    std::size_t ep = token_end(s, ps);
    if (ep == npos) return false;

    std::size_t q = s.find('"', ep);
    if (q == npos) return false;
    i = q + 1;
    if (i + 5 >= s.size() || s[i] != ' ' || s[i + 4] != ' ' || s[i + 5] == ' ') return false;
    if (!is_digit(s[i + 1]) || !is_digit(s[i + 2]) || !is_digit(s[i + 3])) return false;

    r.ip = s.substr(0, e1);
    std::string_view path = s.substr(ps, ep - ps);
    r.path = path.substr(0, path.find('?'));
    r.status = (s[i + 1] - '0') * 100 + (s[i + 2] - '0') * 10 + (s[i + 3] - '0');
    return true;
}

void bump(Counter& c, std::string_view key) {
    auto [it, inserted] = c.try_emplace(std::string(key));
    if (inserted) it->second.order = c.size();
    ++it->second.count;
}

void print_top(const Counter& c, int top) {
    std::vector<std::pair<const std::string*, Entry>> v;
    v.reserve(c.size());
    for (const auto& kv : c) v.emplace_back(&kv.first, kv.second);
    auto cmp = [](const auto& a, const auto& b) {
        if (a.second.count != b.second.count) return a.second.count > b.second.count;
        return a.second.order < b.second.order;
    };
    std::size_t n = std::min<std::size_t>(static_cast<std::size_t>(top), v.size());
    std::partial_sort(v.begin(), v.begin() + static_cast<std::ptrdiff_t>(n), v.end(), cmp);
    for (std::size_t i = 0; i < n; ++i) {
        std::printf("  %6ld  %s\n", v[i].second.count, v[i].first->c_str());
    }
}

std::string fmt_rate(long part, long total) {
    if (total == 0) return "0.0";
    char buf[32];
    std::snprintf(buf, sizeof buf, "%.2f",
                  100.0 * static_cast<double>(part) / static_cast<double>(total));
    std::string s = buf;
    while (s.size() > 1 && s.back() == '0' && s[s.size() - 2] != '.') s.pop_back();
    return s;
}

void usage(std::FILE* out) {
    std::fputs("Usage: logparser [-n TOP] FILE\n"
               "  -n, --top N   number of top entries (default 5)\n",
               out);
}

}  // namespace

int main(int argc, char** argv) {
    int top = 5;
    const char* file = nullptr;
    for (int i = 1; i < argc; ++i) {
        std::string a = argv[i];
        if (a == "-h" || a == "--help") {
            usage(stdout);
            return 0;
        }
        if ((a == "-n" || a == "--top") && i + 1 < argc) {
            top = std::atoi(argv[++i]);
            if (top < 1) {
                usage(stderr);
                return 2;
            }
        } else if (!a.empty() && a[0] == '-') {
            usage(stderr);
            return 2;
        } else {
            file = argv[i];
        }
    }
    if (file == nullptr) {
        usage(stderr);
        return 2;
    }

    static char iobuf[1 << 20];
    std::ifstream in;
    in.rdbuf()->pubsetbuf(iobuf, sizeof iobuf);
    in.open(file);
    if (!in) {
        std::fprintf(stderr, "cannot open file: %s\n", file);
        return 1;
    }

    long total = 0, bad = 0, e4 = 0, e5 = 0;
    Counter ips, paths;
    std::string line;
    while (std::getline(in, line)) {
        std::string_view sv = trim(line);
        if (sv.empty()) continue;
        Record r;
        if (!parse_line(sv, r)) {
            ++bad;
            continue;
        }
        ++total;
        if (r.status >= 400 && r.status < 500) {
            ++e4;
        } else if (r.status >= 500) {
            ++e5;
        }
        bump(ips, r.ip);
        bump(paths, r.path);
    }

    std::printf("Requests:      %ld\n", total);
    std::printf("Parse errors:  %ld\n", bad);
    std::printf("4xx:           %ld\n", e4);
    std::printf("5xx:           %ld (%s%%)\n", e5, fmt_rate(e5, total).c_str());
    std::puts("\nTop IPs:");
    print_top(ips, top);
    std::puts("\nTop paths:");
    print_top(paths, top);
    return 0;
}
