#LuaILS

LuaILS is a custom Lua script designed to enhance the experience of flying RC aircraft by providing telemetry data and feedback for safer, more precise landings. This project originated from personal challenges in aligning RC planes with runways and avoiding obstacles like trees during landing. To address these difficulties, LuaILS integrates GPS data into a telemetry screen and offers audio cues when the aircraft is correctly lined up with the runway.

## Features

    Telemetry Display: A clear visual representation of the aircraft's position relative to the landing strip.
    Audio Feedback: Real-time audio notifications to confirm proper alignment with the runway.
    Compatibility: Designed for use with GPS-enabled RC aircraft, such as the Turbo Timber Evolution.

## Current Limitations

    The GPS coordinates of the landing strip are currently hardcoded, which makes it less flexible for use in varying locations.

## Planned Improvements

###    Dynamic GPS Configuration:
        Implement a user-friendly method to dynamically set the GPS coordinates of the landing strip via the transmitter or a configuration file.
        Explore the possibility of integrating a graphical interface for setting up the coordinates.

###    Multiple Runway Support:
        Allow the script to store and switch between multiple predefined landing strip coordinates for various flying fields.

###    Advanced Audio Cues:
        Enhance audio feedback to include distance or angle deviation alerts, making the alignment process more intuitive.

###    Performance Optimization:
        Refine the script to ensure minimal impact on transmitter performance, even with high-frequency GPS updates.

###    Error Handling:
        Add robust handling for GPS signal loss or incorrect configurations to prevent misinformation during critical moments.