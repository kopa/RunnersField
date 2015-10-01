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
    
    function initialize() {
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
        //dc.drawText(x, y2 + 9, HEADER_FONT, "battery", CENTER);
    }
    
    function drawValues(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.drawText(dc.getWidth() / 4.7, y1 + 21, VALUE_FONT, tenSecondsPace, CENTER);
        dc.drawText(x, y1 + 21, VALUE_FONT, hr.format("%d"), CENTER);
        dc.drawText(dc.getWidth() * 0.26, y + 21, VALUE_FONT, averageInfoPace, CENTER);
        dc.drawText(dc.getWidth() * 0.79, y1 + 21, VALUE_FONT, distance, CENTER);
        dc.drawText(dc.getWidth() * 0.74, y + 21, VALUE_FONT, elapsedTime, CENTER);
        
        dc.drawText(x, 25, Graphics.FONT_MEDIUM, getFormattedDate(Time.now()), CENTER);
        drawBattery(dc);
    }
    
    function drawGps(dc) {
        if (gpsSignal == 3 || gpsSignal == 4) {
            dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_WHITE);
        } else {
            dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_WHITE);
        }
        
        dc.drawText(x + 30, y2 + 14, HEADER_FONT, "GPS", CENTER);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
    }
    
    function drawBattery(dc) {
        var yStart = y2 + 8;
        var xStart = x - 40;
        dc.drawRectangle(xStart, yStart, 35, 15);
        dc.drawRectangle(xStart + 1, yStart + 1, 33, 13);
        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_WHITE);
        for (var i = 0; i < (28 * battery / 100); i = i + 3) {
            dc.fillRectangle(xStart + 3 + i, yStart + 3, 2, 9);    
        }
             
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.fillRectangle(xStart + 34, yStart + 3, 4, 9);
        
        //dc.drawText(xStart + 60, yStart + 6, HEADER_FONT, format("$1$%", [battery.format("%d")]), CENTER);
    }

    function calculatePace(info) {
        var currentSpeed = info.currentSpeed;
        if (currentSpeed != null) {
            paceData.add(info.currentSpeed);
            tenSecondsPace = getMinutesPerKm(computeAverageSpeed());
            averageInfoPace = getMinutesPerKm(info.averageSpeed);
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
            var distanceKm = info.elapsedDistance / 1000;
            var distanceFullString = distanceKm.toString();
            var commaPos = distanceFullString.find(".");
            distance = distanceFullString.substring(0, commaPos + 3);
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

    function getMinutesPerKm(speedMetersPerSecond) {
        if (speedMetersPerSecond != null && speedMetersPerSecond > 0.0) {
            var metersPerMinute = speedMetersPerSecond * 60.0;
            var minutesPerKmDecimal = 1000.0 / metersPerMinute;
            var minutesPerKmFloor = minutesPerKmDecimal.toNumber();
            var seconds = (minutesPerKmDecimal - minutesPerKmFloor) * 60;
            return minutesPerKmDecimal.format("%2d") + ":" + seconds.format("%02d");
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
        var formattedDate = format("$1$:$2$",[date.hour, date.min.format("%02d")]);
        return formattedDate;
    }

}