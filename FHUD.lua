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
local battery = { cells = 3, capacity = 2200 }
local lipoMax = 4.2
local lipoMin = 3.2

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
    local sY = lcd.getTextHeight(FONT_NORMAL)
    primitives.drawTextBox(ren, sensorValText, cX, cY, sX, sY)

    lcd.drawText(
        cX + sX - lcd.getTextWidth(FONT_MINI, label), 
        cY - sY - lcd.getTextHeight(FONT_MINI), 
        label, FONT_MINI)
    
    if (flag ~= nil and flag == true) then
        lcd.drawText(
            cX, 
            cY + sY - lcd.getTextHeight(FONT_MINI), 
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

    local txtHeight = lcd.getTextHeight(FONT_NORMAL)
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

    local text = string.format("%.0f%%", math.floor(v * 100))
    local textHeight = lcd.getTextHeight(FONT_MINI)
    local textWidth = lcd.getTextWidth(FONT_MINI, text)
    lcd.drawText(cX + (sX - textWidth) / 2, cY + sY - textHeight, text, FONT_MINI)
end

function primitives.renderBatteryCellGauge(ren, offsetX, offsetY, width, height, 
    totalVoltage, noOfCells, largestDiff, weakestCell)
    ren:reset()
    lcd.setColor(lcd.getFgColor())
    local textHeight = lcd.getTextHeight(FONT_MINI)

    local v1 = 0
	local cellAvg = 0
	local range = lipoMax - lipoMin
    if (totalVoltage ~= nil and noOfCells ~= nil) then
        cellAvg = totalVoltage / noOfCells
        v1 = (cellAvg - lipoMin) / range
		if (v1 < 0) then 
			v1 = 0
		end
		v1 = math.min(1.0, v1)
    end
    local v2 = 0
    if (largestDiff ~= nil) then
        v2 = math.min(1.0, largestDiff / 0.3 / 4)
    end

    local pad = 5
    local tip = 6
    local cX = offsetX + pad
    local cY = offsetY + pad + tip
    local sX = width - 2 * pad
    local sY = height - 2 * pad - 1
    local barLow = v1 - v2

    local s2 = sY * barLow
    ren:addPoint(cX, cY + sY)
    ren:addPoint(cX, cY + sY - s2)
    ren:addPoint(cX + sX, cY + sY - s2)
    ren:addPoint(cX + sX, cY + sY)
    ren:addPoint(cX, cY + sY)
    ren:renderPolygon()

    ren:reset()
    lcd.setColor(0,0,0)
    local s1 = sY * v2
    ren:addPoint(cX, cY + sY - s2)
    ren:addPoint(cX, cY + sY - s2 - s1)
    ren:addPoint(cX + sX, cY + sY - s2 - s1)
    ren:addPoint(cX + sX, cY + sY - s2)
    ren:addPoint(cX, cY + sY - s2)
    ren:renderPolygon()

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

    local text = string.format("%.2fV", largestDiff)
    local textWidth = lcd.getTextWidth(FONT_MINI, text)
    lcd.drawText(cX + (sX - textWidth) / 2, cY + sY - textHeight, text, FONT_MINI)
	local avgText = string.format("%.2fV", cellAvg)
	textWidth = lcd.getTextWidth(FONT_MINI, avgText)
    lcd.drawText(cX + (sX - textWidth) / 2, cY + sY - textHeight * 2, avgText, FONT_MINI)
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
                mY + (scY - lcd.getTextHeight(FONT_MINI)) / 2, 
                text, FONT_MINI)
        else
            lcd.drawText(
                mX - 2 - lcd.getTextWidth(FONT_MINI, text), 
                mY + (scY - lcd.getTextHeight(FONT_MINI)) / 2, 
                text, FONT_MINI)
        end
    end
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

local function sensorMul6sChanged(value)
    if (value > 0) then
        sensors.mul6s.id = sensorsAvailable[value].id
        system.pSave("mulSensorId", sensors.mul6s.id)
    end
end

local function sensorMul6sModuleChanged(value)
    if (value > 0) then
        sensors.mul6smodule.id = sensorsAvailable[value].id
        system.pSave("mulModuleSensorId", sensors.mul6smodule.id)
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

local function escASensorChanged(value)
    if (value > 0) then
        sensors.escA.id = sensorsAvailable[value].id
        sensors.escA.paramId = sensorsAvailable[value].param
        system.pSave("escASensorId", sensors.escA.id)
        system.pSave("escASensorParamId", sensors.escA.paramId)
    end
end

local function escVSensorChanged(value)
    if (value > 0) then
        sensors.escV.id = sensorsAvailable[value].id
        sensors.escV.paramId = sensorsAvailable[value].param
        system.pSave("escVSensorId", sensors.escV.id)
        system.pSave("escVSensorParamId", sensors.escV.paramId)
    end
end

local function capacitySensorChanged(value)
    if (value > 0) then
        sensors.capacity.id = sensorsAvailable[value].id
        sensors.capacity.paramId = sensorsAvailable[value].param
        system.pSave("capacitySensorId", sensors.capacity.id)
        system.pSave("capacitySensorParamId", sensors.capacity.paramId)
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
    sensors.mul6s.curIndex = -1
    sensors.mul6smodule.curIndex = -1
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
            if (sensor.id == sensors.mul6s.id) then
                sensors.mul6s.curIndex = #sensorsAvailable
            end
            if (sensor.id == sensors.mul6smodule.id) then
                sensors.mul6smodule.curIndex = #sensorsAvailable
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
            if (sensor.id == sensors.escA.id and sensor.param == sensors.escA.paramId) then
                sensors.escA.curIndex = #sensorsAvailable
            end
            if (sensor.id == sensors.escV.id and sensor.param == sensors.escV.paramId) then
                sensors.escV.curIndex = #sensorsAvailable
            end
            if (sensor.id == sensors.capacity.id and sensor.param == sensors.capacity.paramId) then
                sensors.capacity.curIndex = #sensorsAvailable
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
        form.addLabel({label = "Select MUL6S Sensor"})
        form.addSelectbox(list, sensors.mul6s.curIndex, true, sensorMul6sChanged)
        form.addRow(2)
        form.addLabel({label = "Select MUL6S-M Sensor"})
        form.addSelectbox(list, sensors.mul6smodule.curIndex, true, sensorMul6sModuleChanged)
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
        form.addRow(2)
        form.addLabel({label = "Select ESC A Sensor"})
        form.addSelectbox(list, sensors.escA.curIndex, true, escASensorChanged)
        form.addRow(2)
        form.addLabel({label = "Select ESC V Sensor"})
        form.addSelectbox(list, sensors.escV.curIndex, true, escVSensorChanged)
        form.addRow(2)
        form.addLabel({label = "Select Capacity Sensor"})
        form.addSelectbox(list, sensors.capacity.curIndex, true, capacitySensorChanged)
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

    primitives.renderGauge2(ren, 90, 330, 0, 0, szX, szY, sensors.rpm.value, 0, 3600, "%.0f", "RPM", govOn, "GOV")
    primitives.renderGauge2(ren, 90, 330, szX, 0, szX, szY, sensors.throttle.value, 0, 100, "%.1f", "Thr%", false, "")
    primitives.renderGauge2(ren, 90, 330, 0, szY, szX, szY, sensors.temp.value, 20, 120, "%.1f°C", "ESC Temp", false, "")
    primitives.renderGauge2(ren, 90, 330, szX, szY, szX, szY, sensors.becV.value, 0, 10, "%.1fV", "BEC V", false, "")

    local cellVal = {}
    local cellAvg = 0
    local escV = 0
    local escVMax = 0
    local escVMin = 0
    local escAVal = 0
    local escAMax = battery.escMaxA
    local battcX = szX * 3 + szX / 2
    local battszX = szX / 2
    local batVal = 0
    local batMax = battery.capacity

    if (sensors.capacity.valid) then
        batVal = battery.capacity - sensors.capacity.value
    end
    if (sensors.escV.valid) then
        escV = sensors.escV.value 
    end
    if (sensors.escA.valid) then
        escAVal = sensors.escA.value
    end
	if (sensors.mul6smodule.valid) then
		primitives.renderBatteryCellGauge(ren, szX * 3, 0, szX / 2, szY * 2, sensors.mul6smodule.totalVoltage, 
			sensors.mul6smodule.noOfCells, sensors.mul6smodule.largestDiff, sensors.mul6smodule.weakestCell)
	end
	if (sensors.mul6s.valid) then
		cellVal = sensors.mul6s.values
		cellAvg = sensors.mul6s.total / sensors.mul6s.cellCount, 0.07
		primitives.renderCellGraph(ren, szX * 3, 0, szX / 2, szY * 2, cellVal, cellAvg, 0.07)
		vMax = sensors.mul6s.cellCount * lipoMax
		vMin = sensors.mul6s.cellCount * lipoMin
    else 
        vMax = battery.cellCount * lipoMax
        vMin = battery.cellCount * lipoMin
    end
	if (not sensors.mul6s.valid and not sensors.mul6smodule.valid) then
        battcX = szX * 3
        battszX = szX
	end

    primitives.renderGauge2(ren, 90, 330, szX * 2, 0, szX, szY, escV, escVMin, escVMax, "%.1fV", "ESC V", false, "") 
    primitives.renderGauge2(ren, 90, 330, szX * 2, szY, szX, szY, escAVal, 0, escAMax, "%.1fA", "ESC A", false, "") 
    primitives.renderBatteryGauge(ren, battcX, 0, battszX, szY * 2, batVal, batMax)
end

local function getSensors()
    --- MUL6S
    if (sensors.mul6s.id ~= 0) then 
        sensors.mul6s.values = {}
        local cellSum = 0
        for i = 1,6 do
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

    -- MUL6S-M
    if (sensors.mul6smodule.id ~= 0) then
        sensors.mul6smodule.valid = true
        local sensor1 = system.getSensorByID(sensors.mul6smodule.id, 1)
        if (sensor1 and sensor1.valid) then
            sensors.mul6smodule.totalVoltage = sensor1.value
        end
        local sensor2 = system.getSensorByID(sensors.mul6smodule.id, 2)
        if (sensor2 and sensor2.valid) then
            sensors.mul6smodule.noOfCells = sensor2.value
        end
        local sensor3 = system.getSensorByID(sensors.mul6smodule.id, 3)
        if (sensor3 and sensor3.valid) then
            sensors.mul6smodule.lowestVoltage = sensor3.value
        end
        local sensor4 = system.getSensorByID(sensors.mul6smodule.id, 4)
        if (sensor4 and sensor4.valid) then
            sensors.mul6smodule.largestDiff = sensor4.value
        end
        local sensor5 = system.getSensorByID(sensors.mul6smodule.id, 5)
        if (sensor5 and sensor5.valid) then
            sensors.mul6smodule.weakestCell = sensor5.value
        end
        sensors.mul6smodule.valid = sensor1.valid and sensor2.valid and sensor3.valid and sensor4.valid and sensor5.valid
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

    -- ESC A
    if (sensors.escA.id ~= 0 and sensors.escA.paramId ~= 0) then
        local escA = system.getSensorByID(sensors.escA.id, sensors.escA.paramId)
        if (escA and escA.valid) then
            sensors.escA.value = escA.value
            sensors.escA.valid = true
        end
    end

    -- ESC V
    if (sensors.escV.id ~= 0 and sensors.escV.paramId ~= 0) then
        local escV = system.getSensorByID(sensors.escV.id, sensors.escV.paramId)
        if (escV and escV.valid) then
            sensors.escV.value = escV.value
            sensors.escV.valid = true
        end
    end

    -- capacity
    if (sensors.capacity.id ~= 0 and sensors.capacity.paramId ~= 0) then
        local capacity = system.getSensorByID(sensors.capacity.id, sensors.capacity.paramId)
        if (capacity and capacity.valid) then
            sensors.capacity.value = capacity.value
            sensors.capacity.valid = true
        end
    end

    -- BEC V
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

local function initSensors() 
    sensors.mul6s = { id = system.pLoad("mulSensorId", 0), valid = false, cellCount = 0, values = {}, curIndex = 0 }
    sensors.mul6smodule = { id = system.pLoad("mulModuleSensorId", 0), valid = false, totalVoltage = 0, noOfCells = 0, lowestVoltage = 0, largestDiff = 0, weakestCell = 0, curIndex = 0 }
    sensors.rpm = { id = system.pLoad("rpmSensorId", 0), paramId = system.pLoad("rpmSensorParamId", 0), valid = false, value = 0, curIndex = 0}
    sensors.throttle = { id = system.pLoad("throttleSensorId", 0), paramId = system.pLoad("throttleSensorParamId", 0), valid = false, value = 0, curIndex = 0}
    sensors.temp = { id = system.pLoad("tempSensorId", 0), paramId = system.pLoad("tempSensorParamId", 0), valid = false, value = 0, curIndex = 0}
    sensors.becV = { valid = false, value = 0, curIndex = 0}
    sensors.gov = { id = system.pLoad("govSensorId", 0), paramId = system.pLoad("govSensorParamId", 0), valid = false, value = 0, curIndex = 0}
    sensors.escA = { id = system.pLoad("escASensorId", 0), paramId = system.pLoad("escASensorParamId", 0), valid = false, value = 0, curIndex = 0}
    sensors.escV = { id = system.pLoad("escVSensorId", 0), paramId = system.pLoad("escVSensorParamId", 0), valid = false, value = 0, curIndex = 0}
    sensors.capacity = { id = system.pLoad("capacitySensorId", 0), paramId = system.pLoad("capacitySensorParamId", 0), valid = false, value = 0, curIndex = 0}
end

local function initSensors_test() 
    sensors.mul6s = { id = system.pLoad("mulSensorId", 0), valid = true, cellCount = 6, total = 25.0, values = {4.1,4.2,4.1,4.2,4.2,4.2}, curIndex = 0 }
    sensors.mul6smodule = { id = system.pLoad("mulModuleSensorId", 0), valid = false, totalVoltage = 25.0, noOfCells = 6, lowestVoltage = 3.2, largestDiff = 0.1, weakestCell = 5 }
    sensors.rpm = { id = system.pLoad("rpmSensorId", 0), paramId = system.pLoad("rpmSensorParamId", 0), valid = true, value = 2000, curIndex = 0}
    sensors.throttle = { id = system.pLoad("throttleSensorId", 0), paramId = system.pLoad("throttleSensorParamId", 0), valid = true, value = 80, curIndex = 0}
    sensors.temp = { id = system.pLoad("tempSensorId", 0), paramId = system.pLoad("tempSensorParamId", 0), valid = true, value = 75, curIndex = 0}
    sensors.becV = { valid = true, value = 7.5, curIndex = 0}
    sensors.gov = { id = system.pLoad("govSensorId", 0), paramId = system.pLoad("govSensorParamId", 0), valid = false, value = 0, curIndex = 0}
    sensors.escA = { id = system.pLoad("escASensorId", 0), paramId = system.pLoad("escASensorParamId", 0), valid = true, value = 45, curIndex = 0}
    sensors.escV = { id = system.pLoad("escVSensorId", 0), paramId = system.pLoad("escVSensorParamId", 0), valid = true, value = 25.0, curIndex = 0}
    sensors.capacity = { id = system.pLoad("capacitySensorId", 0), paramId = system.pLoad("capacitySensorParamId", 0), valid = true, value = 1100, curIndex = 0}
end

local function initBattery() 
    battery.capacity = system.pLoad("capacity", 2200)
    battery.escMaxA = system.pLoad("escMaxA", 60)
    battery.cellCount = system.pLoad("cellCount", 6)
end

-- Application initialization.
local function init(code)
    initSensors()
    initBattery()
    system.registerTelemetry(1, "Flight HUD", 4, renderTelemetry) 
    system.registerForm(1, MENU_TELEMETRY, "Flight HUD", initForm, nil, printForm)
    print ("Application initialized")
    isInit = true
end
   
-- Application interface
setLanguage()
return {init = init, loop = getSensors, author = "Marc Marais", version = "0.3", name = "Flight HUD"}
