
#define TCMB 2.7 KELVIN //! -270.3 degrees celsius. Temperature of cosmic background radiation.
#define T0C 273.15 KELVIN //! 0 degrees celsius. Freezing point of liquid water.
#define T20C (T0C + 20 KELVIN) //! 20 degrees celsius. Room temperature.
#define T37C (T0C + 37 KELVIN) //! 37 degrees celsius. Body temperature.
#define T100C (T0C + 100 KELVIN) //! 100 degrees celsius. Boiling point of liquid water.

/// 48 degrees celsius. Not super realistic, but there's underwater hot vents!
#define OCEAN_TEMP 321.15 KELVIN
/// 0.85 degrees celsius. Right above the freezing point of liquid water.
#define TRENCH_TEMP 274 KELVIN

/// Converts a temperature in kelvin to celsius.
#define TO_CELSIUS(K) ((K) - T0C)
/// Converts a temperature in kelvin to fahrenheit.
#define TO_FAHRENHEIT(K) (((K) - T0C) * 1.8 + 32)
/// Converts a temperature in celsius to kelvin.
#define FROM_CELSIUS(C) ((C) + T0C)
/// Converts a temperature in fahrenheit to kelvin.
#define FROM_FAHRENHEIT(F) (((F) - 32) / 1.8 + T0C)
