import 'package:flutter/material.dart';

double fastSqrt(double input) {
  if (input <= 0.1) {
    debugPrint("Input is too small.");
    return 0;
  }

  // Initial guess based on the input size
  double guess;
  if (input > 200) {
    guess = input / 20;
  } else {
    guess = input / 10;
  }

  // Iterate using Newton-Raphson method until the result is accurate to one decimal place
  double nextGuess;
  while (true) {
    nextGuess = 0.5 * (guess + input / guess);

    // Stop when the result is within 0.1 of the previous guess (one decimal place accuracy)
    if ((nextGuess - guess).abs() < 0.1) {
      break;
    }

    guess = nextGuess;
  }

  // Return the result rounded to one decimal place
  return (nextGuess * 10).roundToDouble() / 10;
}
