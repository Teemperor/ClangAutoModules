#include "nlohmann/json.hpp"

// for convenience
using json = nlohmann::json;

int main() {
json j;
j["pi"] = 3.141;
j["happy"] = true;
j["name"] = "Niels";
j["nothing"] = nullptr;
j["answer"]["everything"] = 42;
j["list"] = { 1, 0, 2 };
j["object"] = { {"currency", "USD"}, {"value", 42.99} };
json j2 = {
  {"pi", 3.141},
  {"happy", true},
  {"name", "Niels"},
  {"nothing", nullptr},
  {"answer", {
    {"everything", 42}
  }},
  {"list", {1, 0, 2}},
  {"object", {
    {"currency", "USD"},
    {"value", 42.99}
  }}
};
}
