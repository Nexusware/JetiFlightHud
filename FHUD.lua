--primitives = require "primitives"
local primitives = {}

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
    sensorValue, sensorValueMax, format, label, flag, flagLabel)

    local pcnt = 0
    if (sensorValue ~= nil and sensorValueMax ~= nil and sensorValueMax > 0) then
        pcnt = math.floor(sensorValue / sensorValueMax * 100)
    end

    local thickness = math.floor(width * 0.15)
    local radius = (math.min(width, height) - thickness - 4) / 2
    local t = math.floor(tMin + pcnt * (tMax - tMin) / 100)

    if (pcnt < 0) then
        pcnt = 0
    end
    pcnt = math.min(pcnt, 100)

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
    local sY = lcd.getTextHeight(FONT_NORMAL, sensorValText)
    primitives.drawTextBox(ren, sensorValText, cX, cY, sX, sY)

    lcd.drawText(
        cX + sX - lcd.getTextWidth(FONT_MINI, label), 
        cY - sY - lcd.getTextHeight(FONT_MINI, label), 
        label, FONT_MINI)
    
    if (flag ~= nil and flag == true) then
        lcd.drawText(
            cX, 
            cY + sY - lcd.getTextHeight(FONT_MINI, flagLabel), 
            flagLabel, FONT_MINI)
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

    local txtHeight = lcd.getTextHeight(FONT_NORMAL, text)
    lcd.drawText(
        cX + width - lcd.getTextWidth(FONT_NORMAL, text), 
        cY - txtHeight, 
        text)
end

function primitives.renderBatteryGauge(ren, offsetX, offsetY, width, height, 
    sensorValue, sensorValueMax)
    ren:reset()
    lcd.setColor(lcd.getFgColor())

    local v = 0
    if (sensorValue ~= nil and sensorValueMax ~= nil and sensorValueMax > 0) then
        v = sensorValue / sensorValueMax
    end

    local pad = 5
    local tip = 6
    local cX = offsetX + pad
    local cY = offsetY + pad + tip
    local sX = width - 2 * pad
    local sY = height - 2 * pad - 1

    ren:addPoint(cX, cY + sY)
    ren:addPoint(cX, cY + sY - sY * v)
    ren:addPoint(cX + sX, cY + sY - sY * v)
    ren:addPoint(cX + sX, cY + sY)
    ren:addPoint(cX, cY + sY)
    ren:renderPolygon()

    ren:addPoint(cX, cY + sY)
    ren:addPoint(cX, cY + sY - sY * v)
    ren:addPoint(cX + sX, cY + sY - sY * v)
    ren:addPoint(cX + sX, cY + sY)
    ren:addPoint(cX, cY + sY)

    ren:reset()
    ren:addPoint(cX, cY + sY)
    ren:addPoint(cX, cY)
    ren:addPoint(cX + sX, cY)
    ren:addPoint(cX + sX, cY + sY)
    ren:addPoint(cX, cY + sY)
    lcd.setColor(0,0,0)
    ren:renderPolyline(1)

    ren:reset()
    ren:addPoint(cX + sX / 4, cY)
    ren:addPoint(cX + 3 * sX / 4, cY)
    ren:addPoint(cX + 3 * sX / 4, cY - tip)
    ren:addPoint(cX + sX / 4, cY - tip)
    ren:addPoint(cX + sX / 4, cY)
    ren:renderPolygon()
end

function primitives.renderCellGraph(ren, offsetX, offsetY, width, height, cells, avg, maxDev)
    ren:reset()
    lcd.setColor(0,0,0)

    local pad = 5
    local cX = offsetX + pad
    local cY = offsetY + pad
    local sX = width - 2 * pad
    local sY = height - 2 * pad - 1

    local mX = cX + sX / 2
    ren:addPoint(mX, cY)
    ren:addPoint(mX, cY + sY)
    ren:renderPolyline(1)
    lcd.setColor(lcd.getFgColor())

    if (cells ~= nil and #cells == 0) then
        return
    end

    local scY = sY / #cells
    for i, cV in pairs(cells) do 
        local diff = cV - avg
        local scX = diff / maxDev * sX / 2
        lcd.setColor(0,0,0)
        if (scX > sX / 2) then
            scX = sX / 2
            lcd.setColor(lcd.getFgColor())
        end
        if (scX < -sX / 2) then
            scX = -sX / 2
            lcd.setColor(lcd.getFgColor())
        end
        local mY = cY + (i - 1) * scY 
        ren:reset()
        ren:addPoint(mX, mY)
        ren:addPoint(mX + scX, mY)
        ren:addPoint(mX + scX, mY + scY)
        ren:addPoint(mX, mY + scY)
        ren:addPoint(mX, mY)
        ren:renderPolygon()

        local text = string.format("%.0f", math.abs(diff * 1000))
        if (diff < 0) then
            lcd.drawText(
                mX + 2, 
                mY + (scY - lcd.getTextHeight(FONT_MINI, text)) / 2, 
                text, FONT_MINI)
        else
            lcd.drawText(
                mX - 2 - lcd.getTextWidth(FONT_MINI, text), 
                mY + (scY - lcd.getTextHeight(FONT_MINI, text)) / 2, 
                text, FONT_MINI)
        end
    end
end

local lang
local sensors = {}
local isInit = false
local sensorsAvailable = {}
local battery = { cells = 3, capacity = 2200 }

local ren = lcd.renderer()

-- Configure language settings
local function setLanguage()
    -- Set language
    local lng=system.getLocale();
    local file = io.readall("Apps/HudGauge/locale.jsn")
    local obj = json.decode(file)  
    if(obj) then
      lang = obj[lng] or obj[obj.default]
    end
end

local function sensorMuiChanged(value)
    if (value > 0) then
        sensors.mui.id = sensorsAvailable[value].id
        system.pSave("muiSensorId", sensors.mui.id)
    end
end

local function sensorMul6sChanged(value)
    if (value > 0) then
        sensors.mul6s.id = sensorsAvailable[value].id
        system.pSave("mulSensorId", sensors.mul6s.id)
    end
end

local function capacityChanged(value) 
    if (value > 0) then
        battery.capacity = value
        system.pSave("capacity", value)
    end
end

local function escMaxChanged(value) 
    if (value > 0) then
        battery.escMaxA = value
        system.pSave("escMaxA", value)
    end
end

local function cellCountChanged(value) 
    if (value > 0) then
        battery.cellCount = value
        system.pSave("cellCount", value)
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
    sensors.mui.curIndex = -1
    sensors.mul6s.curIndex = -1
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
            if (sensor.id == sensors.mui.id) then
                sensors.mui.curIndex = #sensorsAvailable
            end
            if (sensor.id == sensors.mul6s.id) then
                sensors.mul6s.curIndex = #sensorsAvailable
            end
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

    form.addRow(2)
    form.addLabel({label = "Battery Capacity"})
    form.addIntbox(battery.capacity, 500, 8000, 2200, 0, 50, capacityChanged)
    form.addRow(2)
    form.addLabel({label = "ESC Max A"})
    form.addIntbox(battery.escMaxA, 10, 200, 60, 0, 5, escMaxChanged)
    form.addRow(2)
    form.addLabel({label = "Cells (w/o MUL6S)"})
    form.addIntbox(battery.cellCount, 1, 15, 6, 0, 1, cellCountChanged)
    form.addSpacer(100,10)
    if (#list > 0) then
        form.addRow(2)
        form.addLabel({label = "Select MUI Sensor"})
        form.addSelectbox(list, sensors.mui.curIndex, true, sensorMuiChanged)
        form.addRow(2)
        form.addLabel({label = "Select MUL6S Sensor"})
        form.addSelectbox(list, sensors.mul6s.curIndex, true, sensorMul6sChanged)
        form.addRow(2)
        form.addLabel({label = "Select Throttle Sensor"})
        form.addSelectbox(list, sensors.throttle.curIndex, true, throttleChanged)
        form.addRow(2)
        form.addLabel({label = "Select RPM Sensor"})
        form.addSelectbox(list, sensors.rpm.curIndex, true, sensorRpmChanged)
        form.addRow(2)
        form.addLabel({label = "Select ESC Temp Sensor"})
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

    local szX = width / 4
    local szY = height / 2
    local govOn = false
    if (sensors.gov.value ~= nil) then
        if (sensors.gov.value == 1) then
            govOn = true
        end
    end

    primitives.renderGauge2(ren, 90, 330, 0, 0, szX, szY, sensors.rpm.value, 3600, "%.0f", "RPM", govOn, "GOV")
    primitives.renderGauge2(ren, 90, 330, szX, 0, szX, szY, sensors.throttle.value, 100, "%.1f", "Thr%", false, "")
    primitives.renderGauge2(ren, 90, 330, 0, szY, szX, szY, sensors.temp.value, 100, "%.1f°C", "ESC Temp", false, "")
    primitives.renderGauge2(ren, 90, 330, szX, szY, szX, szY, sensors.becV.value, 10, "%.1fV", "BEC V", false, "")

    local cellVal = {}
    local cellAvg = 0
    local vVal = 0
    local vMax = 0
    local escAVal = 0
    local escAMax = battery.escMaxA
    local battcX = szX * 3 + szX / 2
    local battszX = szX / 2
    local batVal = 0
    local batMax = battery.capacity

    if (sensors.mui.valid) then
        vVal = sensors.mui.values.voltage
        escAVal = sensors.mui.values.current
        batVal = battery.capacity - sensors.mui.values.capacity
    end
    if (sensors.mul6s.valid) then
        cellVal = sensors.mul6s.values
        cellAvg = sensors.mul6s.total / sensors.mul6s.cellCount, 0.07
        primitives.renderCellGraph(ren, szX * 3, 0, szX / 2, szY * 2, cellVal, cellAvg, 0.07)
        vMax = sensors.mul6s.cellCount * 4.2
    else 
        vMax = battery.cellCount * 4.2
        battcX = szX * 3
        battszX = szX
    end

    primitives.renderGauge2(ren, 90, 330, szX * 2, 0, szX, szY, vVal, vMax, "%.1fV", "ESC V", false, "") 
    primitives.renderGauge2(ren, 90, 330, szX * 2, szY, szX, szY, escAVal, escAMax, "%.1fA", "ESC A", false, "") 
    primitives.renderBatteryGauge(ren, battcX, 0, battszX, szY * 2, batVal, batMax)
end

local function getSensors()
    --- MUI
    if (sensors.mui.id ~= 0) then
        --local v = { valid = true, value = 11.1 }
        local v = system.getSensorByID(sensors.mui.id, 1)
        if (v and v.valid) then
            sensors.mui.values.voltage = v.value
            sensors.mui.valid = true
        end
        --local a = {valid = true, value = 50.0}
        local a = system.getSensorByID(sensors.mui.id, 2)
        if (a and a.valid) then
            sensors.mui.values.current = a.value
            sensors.mui.valid = true
        end
        --local c = {valid = true, value = 500}
        local c = system.getSensorByID(sensors.mui.id, 3)
        if (v and v.valid) then
            sensors.mui.values.capacity = c.value
            sensors.mui.valid = true
        end
    end

    --- MUL6S
    if (sensors.mul6s.id ~= 0) then 
        sensors.mul6s.values = {}
        local cellSum = 0
        for i = 1,6 do
            --local sensor = { valid=true, value=3.7 }
            local sensor = system.getSensorByID(sensors.mul6s.id, i)
            if sensor and sensor.valid then
                sensors.mul6s.values[#sensors.mul6s.values + 1] = sensor.value
                sensors.mul6s.valid = true 
                cellSum = cellSum + sensor.value
            end
        end 
        sensors.mul6s.total = cellSum
        sensors.mul6s.cellCount = #sensors.mul6s.values
    end

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

    -- BEC
    local txTel = system.getTxTelemetry()
    if (txTel ~= nil and txTel.rx1Voltage ~= nill) then
        sensors.becV.value = txTel.rx1Voltage
        sensors.becV.valid = true
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

-- Application initialization.
local function init(code)
    sensors.mul6s = { id = system.pLoad("mulSensorId", 0), valid = false, cellCount = 0, values = {} }
    sensors.mui = { id = system.pLoad("muiSensorId", 0), valid = false, values = { voltage = 0, current = 0, capacity = 0} } 
    sensors.rpm = { id = system.pLoad("rpmSensorId", 0), paramId = system.pLoad("rpmSensorParamId", 0), valid = false, value = 0}
    sensors.throttle = { id = system.pLoad("throttleSensorId", 0), paramId = system.pLoad("throttleSensorParamId", 0), valid = false, value = 0}
    sensors.temp = { id = system.pLoad("tempSensorId", 0), paramId = system.pLoad("tempSensorParamId", 0), valid = false, value = 0}
    sensors.becV = { valid = false, value = 0}
    sensors.gov = { id = system.pLoad("govSensorId", 0), paramId = system.pLoad("govSensorParamId", 0), valid = false, value = 0}

    battery.capacity = system.pLoad("capacity", 2200)
    battery.escMaxA = system.pLoad("escMaxA", 60)
    battery.cellCount = system.pLoad("cellCount", 6)

    system.registerTelemetry(1, "Flight HUD", 4, renderTelemetry) 
    system.registerForm(1, MENU_TELEMETRY, "Flight HUD", initForm, nil, printForm)
    print ("Application initialized")
    isInit = true
end
   
-- Application interface
setLanguage()
return {init = init, loop = getSensors, author = "Marc Marais", version = "0.1", name = "Flight HUD"}
