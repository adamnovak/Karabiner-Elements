#include <catch2/catch.hpp>

#include "event_tap_utility.hpp"

TEST_CASE("make_event") {
  {
    auto actual = krbn::event_tap_utility::make_event(kCGEventLeftMouseDown, nullptr);
    REQUIRE(actual->first == krbn::event_type::key_down);
    REQUIRE(actual->second == krbn::event_queue::event(krbn::momentary_switch_event(pqrs::hid::usage_page::button,
                                                                                    pqrs::hid::usage::button::button_1)));
  }
  {
    auto actual = krbn::event_tap_utility::make_event(kCGEventOtherMouseUp, nullptr);
    REQUIRE(actual->first == krbn::event_type::key_up);
    REQUIRE(actual->second == krbn::event_queue::event(krbn::momentary_switch_event(pqrs::hid::usage_page::button,
                                                                                    pqrs::hid::usage::button::button_3)));
  }
}
