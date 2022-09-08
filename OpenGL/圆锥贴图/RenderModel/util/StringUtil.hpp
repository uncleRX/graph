//
//  StringUtil.hpp
//  RenderModel
//
//  Created by 任迅 on 2022/9/7.
//

#ifndef StringUtil_hpp
#define StringUtil_hpp

#include <string.h>

template<class... T>
std::string format(const char *fmt, const T&...t)
{
    const auto len = snprintf(nullptr, 0, fmt, t...);
    std::string r;
    r.resize(static_cast<size_t>(len) + 1);
    snprintf(r.data, len + 1, fmt, t...);  // Bad boy
    r.resize(static_cast<size_t>(len));
    return r;
}

#endif /* StringUtil_hpp */
