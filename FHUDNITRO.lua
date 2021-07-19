-- MIT License
-- Copyright (c) 2020 Nexusware Pty Ltd
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local primitives = {}
local lang
local sensors = {}
local isInit = false
local sensorsAvailable = {}

local ren = lcd.renderer()

function primitives.g2Points(ren, iMin, iMax, offsetX, offsetY, width, height, radius)
    local startP
    local endP
    local inc = 5
    local i = iMin
    while i <= iMax do
        local x = width / 2 + math.cos((i - 90) * math.pi / 180) * radius
        local y = height / 2 + math.sin((i - 90) * math.pi / 180) * radius
        ren:addPoint(offsetX + x, offsetY + y)
        if (startP == nil) then
            startP = {offsetX + x, offsetY + y}
        end
        endP = {offsetX + x, offsetY + y}
        i = i + inc
        if (i > iMax and i - iMax < inc) then
            i = iMax
        end
        inc = 10
    end
    return {startP[1], startP[2], endP[1], endP[2]}
end

function primitives.renderGauge2(ren, tMin, tMax, offsetX, offsetY, width, height,  
    sensorValue, sensorValueMin, sensorValueMax, format, label, flag, flagLabel)

    local pcnt = 0
    if (sensorValue ~= nil and sensorValueMax ~= nil and sensorValueMin ~= nil) then
        pcnt = math.floor((sensorValue - sensorValueMin) / (sensorValueMax - sensorValueMin) * 100)
    end
    if (pcnt < 0) then
        pcnt = 0
    end
    pcnt = math.min(pcnt, 100)

    local thickness = math.floor(width * 0.15)
    local radius = (math.min(width, height) - thickness - 4) / 2
    local t = math.floor(tMin + pcnt * (tMax - tMin) / 100)

    if (pcnt > 0) then
        ren:reset()
        lcd.setColor(lcd.getFgColor())
        primitives.g2Points(ren, tMin, t, offsetX, offsetY, width, height, radius)
        ren:renderPolyline(thickness)
    end

    if (pcnt < 100) then
        ren:reset()
        lcd.setColor(0,0,0)
        local p1 = primitives.g2Points(ren, t, tMax, offsetX, offsetY, width, height, radius + thickness / 2 - 1)
        ren:renderPolyline(1)
    
        ren:reset()
        lcd.setColor(0,0,0)
        local p2 = primitives.g2Points(ren, t, tMax, offsetX, offsetY, width, height, radius - thickness / 2 + 1)
        ren:addPoint(p1[3], p1[4])
        ren:renderPolyline(1)

        if (pcnt == 0) then 
            ren:reset()
            lcd.setColor(0,0,0)
            ren:addPoint(p1[1], p1[2])
            ren:addPoint(p2[1], p2[2])
            ren:renderPolyline(1)
        end
    end

    local sensorValText = string.format(format, sensorValue)
    local cX = offsetX + width / 2 - width / 5
    local cY = offsetY + height / 2
    local sX = radius + thickness / 2 + width / 5
    local sY = lcd.getTextHeight(FONT_BIG)
    primitives.drawTextBox(ren, sensorValText, cX, cY, sX, sY)

    lcd.drawText(
        cX + sX - lcd.getTextWidth(FONT_BIG, label), 
        cY - sY - lcd.getTextHeight(FONT_BIG), 
        label, FONT_BIG)
    
    if (flag ~= nil and flag == true) then
        lcd.drawText(
            cX + sX - lcd.getTextWidth(FONT_BIG, flagLabel), 
            cY + sY - lcd.getTextHeight(FONT_BIG), 
            flagLabel, FONT_BIG)
    end
    
    --lcd.drawRectangle(offsetX, offsetY, width, height, 0)
end

function primitives.drawTextBox(ren, text, cX, cY, width, height)
    ren:reset()
    lcd.setColor(0,0,0)

    ren:addPoint(cX, cY)
    ren:addPoint(cX + width, cY)
    ren:addPoint(cX + width, cY - height)
    ren:addPoint(cX, cY - height)
    ren:addPoint(cX, cY)
    ren:renderPolyline(1)

    local txtHeight = lcd.getTextHeight(FONT_BIG)
    lcd.drawText(
        cX + width - lcd.getTextWidth(FONT_BIG, text), 
        cY - txtHeight, 
        text, FONT_BIG)
end

-- Configure language settings
local function setLanguage()
    local lng=system.getLocale();
    local file = io.readall("Apps/HudGauge/locale.jsn")
    local obj = json.decode(file)  
    if(obj) then
      lang = obj[lng] or obj[obj.default]
    end
end

local function sensorRpmChanged(value)
    if (value > 0) then
        sensors.rpm.id = sensorsAvailable[value].id
        sensors.rpm.paramId = sensorsAvailable[value].param
        system.pSave("rpmSensorId", sensors.rpm.id)
        system.pSave("rpmSensorParamId", sensors.rpm.paramId)
    end
end

local function tempSensorChanged(value)
    if (value > 0) then
        sensors.temp.id = sensorsAvailable[value].id
        sensors.temp.paramId = sensorsAvailable[value].param
        system.pSave("tempSensorId", sensors.temp.id)
        system.pSave("tempSensorParamId", sensors.temp.paramId)
    end
end

local function govSensorChanged(value)
    if (value > 0) then
        sensors.gov.id = sensorsAvailable[value].id
        sensors.gov.paramId = sensorsAvailable[value].param
        system.pSave("govSensorId", sensors.gov.id)
        system.pSave("govSensorParamId", sensors.gov.paramId)
    end
end

local function throttleChanged(value)
    if (value > 0) then
        sensors.throttle.id = sensorsAvailable[value].id
        sensors.throttle.paramId = sensorsAvailable[value].param
        system.pSave("throttleSensorId", sensors.throttle.id)
        system.pSave("throttleSensorParamId", sensors.throttle.paramId)
    end
end

-- Initialise form (configuration)
local function initForm(formId)
    local list = {}
    sensors.rpm.curIndex = -1
    sensors.throttle.curIndex = -1
    sensors.temp.curIndex = -1
    sensors.gov.curIndex = -1

    -- render form
    sensorsAvailable = {}
    local available = system.getSensors();
    local list = {}
    local descr = ""
    for index,sensor in ipairs(available) do
        if (sensor.param == 0) then
            descr = sensor.label
            list[#list+1] = sensor.label
            sensorsAvailable[#sensorsAvailable+1] = sensor
        else
            local sensDesc = string.format("%s - %s [%s]", descr, sensor.label, sensor.unit)
            print(sensDesc)
            list[#list+1] = sensDesc
            sensorsAvailable[#sensorsAvailable+1] = sensor
            if (sensor.id == sensors.throttle.id and sensor.param == sensors.throttle.paramId) then
                sensors.throttle.curIndex = #sensorsAvailable
            end
            if (sensor.id == sensors.rpm.id and sensor.param == sensors.rpm.paramId) then
                sensors.rpm.curIndex = #sensorsAvailable
            end
            if (sensor.id == sensors.temp.id and sensor.param == sensors.temp.paramId) then
                sensors.temp.curIndex = #sensorsAvailable
            end
            if (sensor.id == sensors.gov.id and sensor.param == sensors.gov.paramId) then
                sensors.gov.curIndex = #sensorsAvailable
            end
        end
    end

    if (#list > 0) then
        form.addRow(2)
        form.addLabel({label = "Select Throttle Sensor"})
        form.addSelectbox(list, sensors.throttle.curIndex, true, throttleChanged)
        form.addRow(2)
        form.addLabel({label = "Select RPM Sensor"})
        form.addSelectbox(list, sensors.rpm.curIndex, true, sensorRpmChanged)
        form.addRow(2)
        form.addLabel({label = "Select Temp Sensor"})
        form.addSelectbox(list, sensors.temp.curIndex, true, tempSensorChanged)
        form.addRow(2)
        form.addLabel({label = "Select Gov Sensor"})
        form.addSelectbox(list, sensors.gov.curIndex, true, govSensorChanged)
    end
end

local function renderTelemetry(width, height)
    if (isInit == false) then
        return
    end

    local szX = width / 2
    local szY = height
    local govOn = false
    if (sensors.gov.value ~= nil) then
        if (sensors.gov.value == 1) then
            govOn = true
        end
    end
    local temp = 0
    if (sensors.temp.valid) then
        temp = sensors.temp.value
    end

    primitives.renderGauge2(ren, 90, 330, 0, 0, szX, szY, sensors.rpm.value, 0, 3600, "%.0f", "RPM", govOn, "GOV")
    primitives.renderGauge2(ren, 90, 330, szX, 0, szX, szY, sensors.throttle.value, 0, 100, "%.1f%%", "THR", sensors.temp.valid, string.format("%.1f°C", temp))
end

local function getSensors()
    -- RPM
    if (sensors.rpm.id ~= 0 and sensors.rpm.paramId ~= 0) then
        local rpm = system.getSensorByID(sensors.rpm.id, sensors.rpm.paramId)
        if (rpm and rpm.valid) then
            sensors.rpm.value = rpm.value
            sensors.rpm.valid = true
        end
    end

    -- THR
    if (sensors.throttle.id ~= 0 and sensors.throttle.paramId ~= 0) then
        local thr = system.getSensorByID(sensors.throttle.id, sensors.throttle.paramId)
        if (thr and thr.valid) then
            sensors.throttle.value = thr.value
            sensors.throttle.valid = true
        end
    end

    -- TEMP
    if (sensors.temp.id ~= 0 and sensors.temp.paramId ~= 0) then
        local escTemp = system.getSensorByID(sensors.temp.id, sensors.temp.paramId)
        if (escTemp and escTemp.valid) then
            sensors.temp.value = escTemp.value
            sensors.temp.valid = true
        end
    end

    -- GOV
    if (sensors.gov.id ~= 0 and sensors.gov.paramId ~= 0) then
        local gov = system.getSensorByID(sensors.gov.id, sensors.gov.paramId)
        if (gov and gov.valid) then
            sensors.gov.value = gov.value
            sensors.gov.valid = true
        end
    end
end

local function printForm()
end

local function initSensors() 
    sensors.rpm = { id = system.pLoad("rpmSensorId", 0), paramId = system.pLoad("rpmSensorParamId", 0), valid = false, value = 0, curIndex = 0}
    sensors.throttle = { id = system.pLoad("throttleSensorId", 0), paramId = system.pLoad("throttleSensorParamId", 0), valid = false, value = 0, curIndex = 0}
    sensors.temp = { id = system.pLoad("tempSensorId", 0), paramId = system.pLoad("tempSensorParamId", 0), valid = false, value = 0, curIndex = 0}
    sensors.gov = { id = system.pLoad("govSensorId", 0), paramId = system.pLoad("govSensorParamId", 0), valid = false, value = 0, curIndex = 0}
end

local function initSensors_test() 
    sensors.rpm = { id = system.pLoad("rpmSensorId", 0), paramId = system.pLoad("rpmSensorParamId", 0), valid = true, value = 2000, curIndex = 0}
    sensors.throttle = { id = system.pLoad("throttleSensorId", 0), paramId = system.pLoad("throttleSensorParamId", 0), valid = true, value = 80, curIndex = 0}
    sensors.temp = { id = system.pLoad("tempSensorId", 0), paramId = system.pLoad("tempSensorParamId", 0), valid = true, value = 75, curIndex = 0}
    sensors.gov = { id = system.pLoad("govSensorId", 0), paramId = system.pLoad("govSensorParamId", 0), valid = true, value = 1, curIndex = 0}
end

-- Application initialization.
local function init(code)
    initSensors()
    system.registerTelemetry(1, "Flight HUD Nitro", 4, renderTelemetry) 
    system.registerForm(1, MENU_TELEMETRY, "Flight HUD Nitro", initForm, nil, printForm)
    print ("Application initialized")
    isInit = true
end
   
-- Application interface
setLanguage()
return {init = init, loop = getSensors, author = "Marc Marais", version = "0.3", name = "Flight HUD Nitro"}
