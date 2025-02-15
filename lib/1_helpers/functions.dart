import 'dart:typed_data';

import 'package:flutter/material.dart';

double fastSqrt(double input) {
  if (input <= 0.1 || input.isInfinite || input.isNaN) {
    return 0;
  }

  // Initial guess based on the input size
  double guess = input > 200 ? input / 20 : input / 10;

  var x2 = input * 0.5;
  var y = guess;
  var packedValue = ByteData(4)..setFloat32(0, y);
  var iVal = packedValue.getUint32(0);
  iVal = 0x5f3759df - (iVal >> 1); // Magic number for fast inverse square root
  packedValue.setUint32(0, iVal);
  y = packedValue.getFloat32(0);

  // Use Newton-Raphson for refinement of the guess
  y = y * (1.5 - (x2 * y * y)); // Single iteration for better accuracy

  // Return the refined result
  return 1 / y; // Inverse square root, so we invert it to get the actual sqrt
}

double fastSqrtOld(double input) {
  if (input <= 0.1 || input.isInfinite || input.isNaN) {
    return 0;
  }

  // Initial guess based on the input size
  double guess = input > 200 ? input / 20 : input / 10;

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
