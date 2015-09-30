using Toybox.WatchUi as Ui;
using Toybox.Graphics as Graphics;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.System as System;

//! A DataField that shows some infos
class RunnersView extends Ui.DataField {

    var CENTER = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
    var AVERAGE_SAMPLE_SIZE = 10;
    var tenSecondsPace = "0:00";
    var averageInfoPace = "0:00";
    var paceData = new DataQueue(AVERAGE_SAMPLE_SIZE);
    var hr = 0;
    var distance = "0.0";
    var elapsedTime = "0:0";
    var battery = 0;
    var x;
    var y;
    var y1;
    var y2;

    function initialize() {
    }

    //! The given info object contains all the current workout
    function compute(info) {
        
        calculatePace(info);
        
        calculateHeartRate(info);
        
        calculateDistance(info);
        
        calculateElapsedTime(info);
        
        calculateBattery();
    }
    
    function onUpdate(dc) {
        
        drawGrid(dc);    
        
        drawHeaders(dc);
        
        drawValues(dc);
    }
    
    function onLayout(dc) {
        // calculate values for grid
        y = dc.getHeight() / 2;
        y1 = dc.getHeight() / 4;
        y2 = dc.getHeight() - y1;
        x = dc.getWidth() / 2;
    }
    
    //! API functions
    
    //! function setLayout(layout) {}
    //! function onShow() {}
    //! function onHide() {}

    function drawGrid(dc) {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_WHITE);
        dc.drawLine(0, y1, dc.getWidth(), y1);
        dc.drawLine(0, y, dc.getWidth(), y);
        dc.drawLine(x, y, x, y2);
        dc.drawLine(x-30, y1, x-30, y); 
        dc.drawLine(x+30, y1, x+30, y); 
        dc.drawLine(0, y2, dc.getWidth(), y2);      
    }

    function drawHeaders(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.drawText(x, 13, Graphics.FONT_XTINY, "time", CENTER);
        dc.drawText(dc.getWidth() / 6, y / 1.6, Graphics.FONT_XTINY, "pace", CENTER);
        dc.drawText(dc.getWidth() / 4, y + (y / 8.6), Graphics.FONT_XTINY, "avg pace", CENTER);
        dc.drawText(x, y / 1.6, Graphics.FONT_XTINY, "hr", CENTER); 
        dc.drawText(dc.getWidth() * 0.80, y / 1.6, Graphics.FONT_XTINY, "distance", CENTER);
        dc.drawText(dc.getWidth() * 0.75, y + (y / 8.6), Graphics.FONT_XTINY, "timer", CENTER);
        dc.drawText(x, y2 + 13, Graphics.FONT_XTINY, "battery", CENTER);
    }
    
    function drawValues(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.drawText(x, 33, Graphics.FONT_MEDIUM, getFormattedDate(Time.now()), CENTER);
        dc.drawText(dc.getWidth() / 6, y / 1.2, Graphics.FONT_MEDIUM, tenSecondsPace, CENTER);
        dc.drawText(x, y / 1.2, Graphics.FONT_MEDIUM, hr.format("%d"), CENTER);
        dc.drawText(dc.getWidth() / 4, y + (y / 3.2), Graphics.FONT_MEDIUM, averageInfoPace, CENTER);
        dc.drawText(dc.getWidth() * 0.80, y / 1.2, Graphics.FONT_MEDIUM, distance, CENTER);
        dc.drawText(dc.getWidth() * 0.75, y + (y / 3.2), Graphics.FONT_MEDIUM, elapsedTime, CENTER);
        dc.drawText(x + 25, y2 + 29, Graphics.FONT_XTINY, format("$1$%", [battery.format("%d")]), CENTER);
        drawBattery(dc);
        
    }
    
    function drawBattery(dc) {
        dc.drawRectangle(x-35, y2 + 23, 35, 15);
        dc.drawRectangle(x-34, y2 + 24, 33, 13);
        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_WHITE);
        for (var i = 0; i < (28 * battery / 100); i = i + 3) {
            dc.fillRectangle(x-32 + i, y2 + 26, 2, 9);    
        }
             
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.fillRectangle(x-1, y2+26, 4, 9);
    }

    function calculatePace(info) {
        var currentSpeed = info.currentSpeed;
        if (currentSpeed != null) {
            paceData.add(info.currentSpeed);
            tenSecondsPace = getMinutesPerKm(computeAverageSpeed());
            averageInfoPace = getMinutesPerKm(info.averageSpeed);
        } else {
            paceData.reset();
            tenSecondsPace = "0:00";
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
        if (info.elapsedDistance != null) {
            var distanceKm = info.elapsedDistance / 1000;
            var distanceFullString = distanceKm.toString();
            var commaPos = distanceFullString.find(".");
            distance = distanceFullString.substring(0, commaPos + 3);
        }
    }
    
    function calculateElapsedTime(info) {   
        if (info.elapsedTime != null) {
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

    function getMinutesPerKm(speedMetersPerSecond) {
        var metersPerMinute = speedMetersPerSecond * 60.0;
        var minutesPerKmDecimal = 1000.0 / metersPerMinute;
        var minutesPerKmFloor = minutesPerKmDecimal.toNumber();
        var seconds = (minutesPerKmDecimal - minutesPerKmFloor) * 60;
        return minutesPerKmDecimal.format("%2d") + ":" + seconds.format("%02d"); 
    }
    
    function computeAverageSpeed() {
        var s = paceData.getSize();
        var data = paceData.getData();
        var sumOfData = 0.0;
        for (var i = 0; i < s; i++) {
            sumOfData = sumOfData + data[i];
        }
        return sumOfData / s;
    }
    
    function getFormattedDate(moment) {
        var date = Calendar.info(moment, 0);
        var formattedDate = format("$1$:$2$",[date.hour, date.min.format("%02d")]);
        return formattedDate;
    }

}