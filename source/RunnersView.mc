using Toybox.WatchUi as Ui;
using Toybox.Graphics as Graphics;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.System as System;

//! A DataField that shows some infos.
//!
//! @author Konrad Paumann
class RunnersView extends Ui.DataField {

    hidden const CENTER = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
    hidden const AVERAGE_SAMPLE_SIZE = 10;
    hidden const HEADER_FONT = Graphics.FONT_XTINY;
    hidden const VALUE_FONT = Graphics.FONT_NUMBER_MEDIUM;
    hidden const ZERO_TIME = "0:00";
    hidden const ZERO_DISTANCE = "0.00";
    
    hidden var paceData = new DataQueue(AVERAGE_SAMPLE_SIZE);
    hidden var tenSecondsPace = ZERO_TIME;
    hidden var averageInfoPace = ZERO_TIME;
    hidden var hr = 0;
    hidden var distance = ZERO_DISTANCE;
    hidden var elapsedTime = ZERO_TIME;
    hidden var battery = 0;
    hidden var gpsSignal = 0; //Position 0 not avail ... 4 good
    hidden var x;
    hidden var y;
    hidden var y1;
    hidden var y2;
    hidden var kmOrMileInMeters = 1000;
    hidden var is24Hour = true;
    hidden var distanceUnits = System.UNIT_METRIC;
    
    function initialize() {
        setDeviceSettingsDependentVariables();
    }

    //! The given info object contains all the current workout
    function compute(info) {
        calculatePace(info);
        
        calculateHeartRate(info);
        
        calculateDistance(info);
        
        calculateElapsedTime(info);
        
        calculateBattery();
        
        calculateGpsSignal(info);
    }
    
    function onUpdate(dc) {
        drawValues(dc);
        drawHeaders(dc);
        drawGrid(dc);
        drawGps(dc);    
    }
    
    function onLayout(dc) {
        // calculate values for grid
        y = dc.getHeight() / 2 + 5;
        y1 = dc.getHeight() / 4.7 + 5;
        y2 = dc.getHeight() - y1 + 10;
        x = dc.getWidth() / 2;
    }
    
    //! API functions
    
    //! function setLayout(layout) {}
    //! function onShow() {}
    //! function onHide() {}

    function setDeviceSettingsDependentVariables() {
        distanceUnits = System.getDeviceSettings().distanceUnits;
        if (distanceUnits == System.UNIT_METRIC) {
            kmOrMileInMeters = 1000;
        } else {
            kmOrMileInMeters = 1610;
        }
        is24Hour = System.getDeviceSettings().is24Hour;
    }

    function drawGrid(dc) {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_WHITE);
        dc.setPenWidth(2);
        dc.drawLine(0, y1, dc.getWidth(), y1);
        dc.drawLine(0, y, dc.getWidth(), y);
        dc.drawLine(x, y, x, y2);
        dc.drawLine(x-27, y1, x-27, y); 
        dc.drawLine(x+27, y1, x+27, y); 
        dc.drawLine(0, y2, dc.getWidth(), y2);  
        dc.setPenWidth(1);    
    }

    function drawHeaders(dc) {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_WHITE);
        //dc.drawText(x, 8, HEADER_FONT, "TIME", CENTER);
        dc.drawText(dc.getWidth() / 4.7, y - 10, HEADER_FONT, "PACE", CENTER);
        dc.drawText(dc.getWidth() * 0.28, y2 - 10, HEADER_FONT, "AVG PACE", CENTER);
        dc.drawText(x, y - 10, HEADER_FONT, "HR", CENTER); 
        dc.drawText(dc.getWidth() * 0.80, y - 10, HEADER_FONT, "DISTANCE", CENTER);
        dc.drawText(dc.getWidth() * 0.74, y2 - 10, HEADER_FONT, "TIMER", CENTER);
        dc.drawText(dc.getWidth() / 2, y2 + 31, HEADER_FONT, distanceUnits == System.UNIT_METRIC ? "metric" : "statute", CENTER);
    }
    
    function drawValues(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.drawText(dc.getWidth() / 4.7, y1 + 21, VALUE_FONT, tenSecondsPace, CENTER);
        
        drawHeartRate(dc);
        
        dc.drawText(dc.getWidth() * 0.26, y + 21, VALUE_FONT, averageInfoPace, CENTER);
        dc.drawText(dc.getWidth() * 0.79, y1 + 21, VALUE_FONT, distance, CENTER);
        dc.drawText(dc.getWidth() * 0.74, y + 21, VALUE_FONT, elapsedTime, CENTER);
        
        dc.drawText(x, 25, Graphics.FONT_MEDIUM, getFormattedDate(Time.now()), CENTER);
        drawBattery(dc);
    }
    
    function drawHeartRate(dc) {
        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_WHITE);
        dc.drawText(x, y1 + 21, VALUE_FONT, hr.format("%d"), CENTER);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
    }
    
    function drawGps(dc) {
        if (gpsSignal == 3 || gpsSignal == 4) {
            dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_WHITE);
        } else {
            dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_WHITE);
        }
        
        dc.drawText(x + 28, y2 + 13, HEADER_FONT, "GPS", CENTER);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
    }
    
    function drawBattery(dc) {
        var yStart = y2 + 6;
        var xStart = x - 40;
        var length = 35;
        var height = 17;
        var batteryColor = Graphics.COLOR_DK_GREEN;
        
        if (battery < 10) {
            batteryColor = Graphics.COLOR_DK_RED;
            dc.setColor(batteryColor, Graphics.COLOR_WHITE);
            dc.drawText(xStart + 20, yStart + 7, HEADER_FONT, format("$1$%", [battery.format("%d")]), CENTER);
        }
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.drawRectangle(xStart, yStart, length, height);
        dc.drawRectangle(xStart + 1, yStart + 1, length - 2, height - 2);
        if (battery < 10) {
            dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_WHITE);
        } else {
            dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_WHITE);
        }
        for (var i = 0; i < ((length - 7) * battery / 100); i = i + 3) {
            dc.fillRectangle(xStart + 3 + i, yStart + 3, 2, height - 6);    
        }
             
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.fillRectangle(xStart + length - 1, yStart + 3, length - 31, height - 6);
    }

    function calculatePace(info) {
        var currentSpeed = info.currentSpeed;
        if (currentSpeed != null) {
            paceData.add(info.currentSpeed);
            tenSecondsPace = getMinutesPerKmOrMile(computeAverageSpeed());
            averageInfoPace = getMinutesPerKmOrMile(info.averageSpeed);
        } else {
            paceData.reset();
            tenSecondsPace = ZERO_TIME;
        }
    }
    
    function calculateHeartRate(info) {
        if (info.currentHeartRate != null) {
            hr = info.currentHeartRate;
        } else {
            hr = 0;
        }
    }

    function calculateDistance(info) {
        if (info.elapsedDistance != null && info.elapsedDistance > 0) {
            var distanceKmOrMiles = info.elapsedDistance / kmOrMileInMeters;
            distance = distanceKmOrMiles.format("%.2f");
        }
    }
    
    function calculateElapsedTime(info) {
        if (info.elapsedTime != null && info.elapsedTime > 0) {
            var hours = null;
            var minutes = info.elapsedTime / 1000 / 60;
            var seconds = info.elapsedTime / 1000 % 60;
            
            if (minutes >= 60) {
                hours = minutes / 60;
                minutes = minutes % 60;
            }
            
            if (hours == null) {
                elapsedTime = minutes.format("%d") + ":" + seconds.format("%02d");
            } else {
                elapsedTime = hours.format("%d") + ":" + minutes.format("%02d") + ":" + seconds.format("%02d");
            }
        }
    }
    
    function calculateBattery() {
        battery = System.getSystemStats().battery;
    }

    function calculateGpsSignal(info) {
        gpsSignal = info.currentLocationAccuracy;
    }

    function getMinutesPerKmOrMile(speedMetersPerSecond) {
        if (speedMetersPerSecond != null && speedMetersPerSecond > 0.0) {
            var metersPerMinute = speedMetersPerSecond * 60.0;
            var minutesPerKmOrMilesDecimal = kmOrMileInMeters / metersPerMinute;
            var minutesPerKmOrMilesFloor = minutesPerKmOrMilesDecimal.toNumber();
            var seconds = (minutesPerKmOrMilesDecimal - minutesPerKmOrMilesFloor) * 60;
            return minutesPerKmOrMilesDecimal.format("%2d") + ":" + seconds.format("%02d");
        }
        return ZERO_TIME;
    }
    
    function computeAverageSpeed() {
        var size = 0;
        var data = paceData.getData();
        var sumOfData = 0.0;
        for (var i = 0; i < data.size(); i++) {
            if (data[i] != null) {
                sumOfData = sumOfData + data[i];
                size++;
            }
        }
        if (sumOfData > 0) {
            return sumOfData / size;
        }
        return 0.0;
    }
    
    function getFormattedDate(moment) {
        var date = Calendar.info(moment, 0);
        var formattedDate;
        if (is24Hour) {
            formattedDate = format("$1$:$2$",[date.hour, date.min.format("%02d")]);
        } else {
            formattedDate = format("$1$:$2$ " + (date.hour < 12 ? "am" : "pm"),[formatHour(date.hour), date.min.format("%02d")]);
        }
        return formattedDate;
    }
    
    function formatHour(hour) {
        if (hour < 1) {
            return hour + 12;
        }
        if (hour >  12) {
            return hour - 12;
        }
        return hour;      
    }
}