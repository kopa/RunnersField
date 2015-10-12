# RunnersField

This is a Data Field for the Fenix 3 that shows multiple values on a single field. 
RunnersField is open source and its code resides at github: https://github.com/kopa/RunnersField

Release versions are published in the [Garmin App Store](https://apps.garmin.com/en-US/apps/8428701b-e621-4156-9d4e-37d92b30151f)

## Feedback: 
https://forums.garmin.com/showthread.php?327411-DataFields-RunnersField

## Features:
* TIME: 12/24h mode based on system settings.
* PACE: pace in km/min or miles/min based on system settings
* AVG PACE: average pace over the whole activity
* DISTANCE: elapsed distance in km or miles based on system settings
* DURATION: duration of the activity in [hh:]mm:ss
* GPS: green if good/acceptable signal, red otherwise
* battery: visualization of battery percentage. If battery value < 10% the exact value will be shown and the green indicator bar turns red 
* unit system in use: km will be shown when metric system is set in the settings, miles if statute units are configured.


## Install Instructions:

A Data Field needs to be set up within the settings for a given activity (like Run)

* Long Press UP
* Settings
* Apps
* Run
* Data Screens
* Screen N
* Layout
* Select single field
* Field 1
* Select ConnectIQ Fields
* Select RunnersField
* Long Press Down to go back to watch face

## Usage:

Start Run activity.
Hopefully you see the RunnersField datafield.

* The pace is the average pace over the last 10 seconds

## Changelog 1.0.2:
* Fix when black background is configured in device settings.
* Add battery percentage if < 10% left and make visualization red.
* Fix irrelevant slow pace values
* Change string TIMER to DURATION
* Change string metric to km and statute to miles

## Changelog 1.0.1:

* Time mode is now dependent on device settings (12/24 hours mode)
* Distance and pace will be presented dependent on device settings (metric [km, km/min] or statute [miles, miles/min]), "metric" or "statute" will be shown below battery/gps
* HR is now dark red to visually decipher the different values faster

## Changelog 1.0.0:

* Time of day
* Current Pace (average over 10 seconds)
* Average Pace
* Heart Rate
* Distance
* Timer
* Battery Status
* GPS Status (green = gps lock, red = no gps lock)
