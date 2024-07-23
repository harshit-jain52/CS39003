#include <iostream>
#include <string>
#include <stack>
#include <vector>
#include <algorithm> 
#include <cctype>
#include <locale>
using namespace std;
typedef long long ll;

inline void ltrim(string &s) {
    s.erase(s.begin(), find_if(s.begin(), s.end(), [](unsigned char ch) {
        return !isspace(ch);
    }));
}

inline void rtrim(string &s) {
    s.erase(find_if(s.rbegin(), s.rend(), [](unsigned char ch) {
        return !isspace(ch);
    }).base(), s.end());
}

inline bool is_num(const string &s){
    return all_of(s.begin(),s.end(),::isdigit);
}

inline bool has_digit(const string &s){
    return any_of(s.begin(),s.end(),::isdigit);
}

inline bool is_space_num(const string &s){
    for(char c: s) if(!isspace(c) && !isdigit(c)) return false;
    return true;
}

inline void simplify(string &s){
    ltrim(s);
    rtrim(s);

    int sz = s.size();
    stack<int>st;
    for(int i=0;i<sz;i++){
        if(s[i]=='(') st.push(i);
        else if(s[i]==')'){
            if(st.empty()) throw invalid_argument("Invalid Arithmetic Expression");
            st.pop();
        }
    }

    if(!st.empty()) throw invalid_argument("Invalid Arithmetic Expression");

    while(sz && s[0]=='(' && s[sz-1]==')'){
        for(int i=0;i<sz;i++){
            if(s[i]=='(') st.push(i);
            else if(s[i]==')'){
                if(i==sz-1 && st.top()==0){
                    s = s.substr(1,sz-2);
                }
                st.pop();
            }
        }
        if(sz==s.size()) break;
        sz = s.size();
    }
    
    if(!has_digit(s)){
        throw invalid_argument("Invalid Arithmetic Expression");
    }
}

ll evalterm(string&);
ll evalsum(string &);

int main(){
    string exp;
    getline(cin, exp);
    
    cout << evalsum(exp) << endl;
}

ll evalsum(string &exp){
    simplify(exp);    
    // cout << exp << endl;
    if(is_num(exp)) return stoll(exp);
    if(is_space_num(exp)) throw invalid_argument("Invalid Arithmetic Expression");

    string tmp="";
    vector<string>summands;
    int ct=0;
    for(char c: exp){
        if(c=='+' && ct==0){
            summands.push_back(tmp);
            tmp="";
        }
        else tmp += c;

        if(c=='(') ct++;
        if(c==')') ct--;
    }
    summands.push_back(tmp);

    ll ans = 0;
    for(string s: summands) ans += evalterm(s);
    return ans;
}

ll evalterm(string &exp){
    simplify(exp);    
    // cout << exp << endl;

    if(is_num(exp)) return stoll(exp);
    if(is_space_num(exp)) throw invalid_argument("Invalid Arithmetic Expression");

    int ct=0;
    for(char c: exp){
        if(c=='(') ct++;
        if(c==')') ct--;
        if(c=='+' && ct==0) return evalsum(exp);
    }

    string tmp="";
    vector<string>terms;
    ct=0;
    for(char c: exp){
        if(c=='*' && ct==0){
            terms.push_back(tmp);
            tmp="";
        }
        else tmp += c;

        if(c=='(') ct++;
        if(c==')') ct--;
    }
    terms.push_back(tmp);

    ll ans = 1;
    for(string t: terms) ans *= evalsum(t);
    return ans;
}

