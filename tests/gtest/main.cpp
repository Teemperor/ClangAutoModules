#include "gtest/gtest.h"

int Neg(int i) { return -i; }

TEST(NegTest, Negative) {
  EXPECT_EQ(5, Neg(-5));
  EXPECT_EQ(1, Neg(-1));
  EXPECT_GT(Neg(-10), 0);
}
