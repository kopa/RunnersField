using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Graphics;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.System as System;

//! @author Konrad Paumann
class RunnersField extends App.AppBase {

    function getInitialView() {
        return [ new RunnersView() ];
    }

}

//! A DataField that shows some infos.
//!
//! @author Konrad Paumann
class RunnersView extends Ui.DataField {

    hidden const CENTER = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
    hidden const HEADER_FONT = Graphics.FONT_XTINY;
    hidden const VALUE_FONT = Graphics.FONT_NUMBER_MEDIUM;
    hidden const ZERO_TIME = "0:00";
    hidden const ZERO_DISTANCE = "0.00";
    
    hidden var kmOrMileInMeters = 1000;
    hidden var is24Hour = true;
    hidden var distanceUnits = System.UNIT_METRIC;
        
    hidden var paceData = new DataQueue(10);
    hidden var pace = ZERO_TIME;
    hidden var avgPace = ZERO_TIME;
    hidden var hr = 0;
    hidden var distance = ZERO_DISTANCE;
    hidden var duration = ZERO_TIME;
    hidden var time = "";
    hidden var ampm = "";
    hidden var battery = 0;
    hidden var gpsSignal = 0;
    
    function initialize() {
        setDeviceSettingsDependentVariables();
    }

    //! The given info object contains all the current workout
    function compute(info) {
        computeClockTime(System.getClockTime());
        computePace(info);
        computeHeartRate(info);
        computeDistance(info);
        computeDuration(info);
        computeBattery();
        computeGpsSignal(info);
    }
    
    function onUpdate(dc) {
        //FIXME: this is a workaround. when using sdk 1.2.0 merge branch sdk120
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillRectangle(0, 0, 218, 218);
        
        drawValues(dc);
        drawBattery(dc, 64, 186, 25, 15);
        drawGps(dc, 136, 181);
        
        drawHeaders(dc);
        drawGrid(dc);
    }

    function setDeviceSettingsDependentVariables() {
        distanceUnits = System.getDeviceSettings().distanceUnits;
        if (distanceUnits == System.UNIT_METRIC) {
            kmOrMileInMeters = 1000;
        } else {
            kmOrMileInMeters = 1610;
        }
        is24Hour = System.getDeviceSettings().is24Hour;
        
    }
    
    function computePace(info) {
        var currentSpeed = info.currentSpeed;
        if (currentSpeed != null) {
            paceData.add(info.currentSpeed);
            pace = getMinutesPerKmOrMile(computeAverageSpeed());
            avgPace = getMinutesPerKmOrMile(info.averageSpeed);
        } else {
            paceData.reset();
            pace = ZERO_TIME;
        }
    }
    
    function computeHeartRate(info) {
        if (info.currentHeartRate != null) {
            hr = info.currentHeartRate;
        } else {
            hr = 0;
        }
    }

    function computeDistance(info) {
        if (info.elapsedDistance != null && info.elapsedDistance > 0) {
            var distanceKmOrMiles = info.elapsedDistance / kmOrMileInMeters;
            if (distanceKmOrMiles < 100) {
                distance = distanceKmOrMiles.format("%.2f");
            } else {
                distance = distanceKmOrMiles.format("%.1f");
            }
        } else {
            distance = ZERO_DISTANCE;
        }
    }
    
    function computeDuration(info) {
        var timer = info.elapsedTime;
        if (timer != null && timer > 0) {
            var hours = null;
            var minutes = timer / 1000 / 60;
            var seconds = timer / 1000 % 60;
            
            if (minutes >= 60) {
                hours = minutes / 60;
                minutes = minutes % 60;
            }
            
            if (hours == null) {
                duration = minutes.format("%d") + ":" + seconds.format("%02d");
            } else {
                duration = hours.format("%d") + ":" + minutes.format("%02d") + ":" + seconds.format("%02d");
            }
        } else {
            duration = ZERO_TIME;
        } 
    }
    
    function computeClockTime(clockTime) {
        if (is24Hour) {
            time = Lang.format("$1$:$2$", [clockTime.hour, clockTime.min.format("%.2d")]);
            ampm = "";
        } else {
            time = Lang.format("$1$:$2$", [computeHour(clockTime.hour), clockTime.min.format("%.2d")]);
            ampm = (clockTime.hour < 12) ? "am" : "pm";
        }
    }
    
    function computeBattery() {
        battery = System.getSystemStats().battery;
    }

    function computeGpsSignal(info) {
        gpsSignal = info.currentLocationAccuracy;
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
    
    function computeHour(hour) {
        if (hour < 1) {
            return hour + 12;
        }
        if (hour >  12) {
            return hour - 12;
        }
        return hour;      
    }
    
    function drawGrid(dc) {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_WHITE);
        dc.drawLine(0, 104, dc.getWidth(), 104);
        dc.setPenWidth(1);    
    }
    
    function drawHeaders(dc) {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_WHITE);
        //TODO: get text from resource file if memory limit gets higher
        dc.drawText(50, 38, HEADER_FONT, "PACE", CENTER);
        dc.drawText(57, 165, HEADER_FONT, "AVG PACE", CENTER);
        dc.drawText(109, 38, HEADER_FONT, "HR", CENTER); 
        dc.drawText(170, 38, HEADER_FONT, "DIST", CENTER);
        dc.drawText(158, 165, HEADER_FONT, "DURATION", CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(112, 207, HEADER_FONT, distanceUnits == System.UNIT_METRIC ? "(km)" : "(mi)", CENTER);
    
    }
    
    function drawValues(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.drawText(50, 70, VALUE_FONT, pace, CENTER);
        
        drawHeartRate(dc);
        
        dc.drawText(57, 130, VALUE_FONT, avgPace, CENTER);
        dc.drawText(170 , 70, VALUE_FONT, distance, CENTER);
        dc.drawText(158, 130, VALUE_FONT, duration, CENTER);
        
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0,0,218,25);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(109, 12, Graphics.FONT_MEDIUM, time, CENTER);
        dc.drawText(148, 15, HEADER_FONT, ampm, CENTER);
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0,180,218,38);
    }
    
    function drawHeartRate(dc) {
        dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_WHITE);
        dc.drawText(109, 70, VALUE_FONT, hr.format("%d"), CENTER);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
    }
    
    function drawBattery(dc, xStart, yStart, width, height) {                
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillRectangle(xStart, yStart, width, height);
        if (battery < 10) {
            dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(xStart+3 + width / 2, yStart + 6, HEADER_FONT, format("$1$%", [battery.format("%d")]), CENTER);
        }
        
        if (battery < 10) {
            dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_WHITE);
        } else if (battery < 30) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_WHITE);
        } else {
            dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_WHITE);
        }
        dc.fillRectangle(xStart + 1, yStart + 1, (width-2) * battery / 100, height - 2);
            
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillRectangle(xStart + width - 1, yStart + 3, 4, height - 6);
    }
    
    //! convert to integer - round ceiling 
    function toNumberCeil(float) {
        var floor = float.toNumber();
        if (float - floor > 0) {
            return floor + 1;
        }
        return floor;
    }
    
    function drawGps(dc, xStart, yStart) {
        if (gpsSignal < 2) {
            drawGpsSign(dc, xStart, yStart, Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY);
        } else if (gpsSignal == 2) {
            drawGpsSign(dc, xStart, yStart, Graphics.COLOR_DK_GREEN, Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY);
        } else if (gpsSignal == 3) {          
            drawGpsSign(dc, xStart, yStart, Graphics.COLOR_DK_GREEN, Graphics.COLOR_DK_GREEN, Graphics.COLOR_LT_GRAY);
        } else {
            drawGpsSign(dc, xStart, yStart, Graphics.COLOR_DK_GREEN, Graphics.COLOR_DK_GREEN, Graphics.COLOR_DK_GREEN);
        }
        
        //dc.drawText(x + 28, y2 + 13, HEADER_FONT, "GPS", CENTER);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
    }
    
    function drawGpsSign(dc, xStart, yStart, color1, color2, color3) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.drawRectangle(xStart - 1, yStart + 11, 8, 10);
        dc.setColor(color1, Graphics.COLOR_WHITE);
        dc.fillRectangle(xStart, yStart + 12, 6, 8);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.drawRectangle(xStart + 6, yStart + 7, 8, 14);
        dc.setColor(color2, Graphics.COLOR_WHITE);
        dc.fillRectangle(xStart + 7, yStart + 8, 6, 12);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.drawRectangle(xStart + 13, yStart + 3, 8, 18);
        dc.setColor(color3, Graphics.COLOR_WHITE);
        dc.fillRectangle(xStart + 14, yStart + 4, 6, 16);
    }
    
    function getMinutesPerKmOrMile(speedMetersPerSecond) {
        if (speedMetersPerSecond != null && speedMetersPerSecond > 0.2) {
            var metersPerMinute = speedMetersPerSecond * 60.0;
            var minutesPerKmOrMilesDecimal = kmOrMileInMeters / metersPerMinute;
            var minutesPerKmOrMilesFloor = minutesPerKmOrMilesDecimal.toNumber();
            var seconds = (minutesPerKmOrMilesDecimal - minutesPerKmOrMilesFloor) * 60;
            return minutesPerKmOrMilesDecimal.format("%2d") + ":" + seconds.format("%02d");
        }
        return ZERO_TIME;
    }
}

//! A circular queue implementation.
//! @author Konrad Paumann
class DataQueue {

    //! the data array.
    hidden var data;
    hidden var maxSize = 0;
    hidden var pos = 0;

    //! precondition: size has to be >= 2
    function initialize(arraySize) {
        data = new[arraySize];
        maxSize = arraySize;
    }
    
    //! Add an element to the queue.
    function add(element) {
        data[pos] = element;
        pos = (pos + 1) % maxSize;
    }
    
    //! Reset the queue to its initial state.
    function reset() {
        for (var i = 0; i < data.size(); i++) {
            data[i] = null;
        }
        pos = 0;
    }
    
    //! Get the underlying data array.
    function getData() {
        return data;
    }
}