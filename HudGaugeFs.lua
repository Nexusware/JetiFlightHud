primitives = require "primitives"

local lang
local sensorId
local paramId
local sensorLabel
local sensorsAvailable = {}

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

-- Sensor changed selection box
local function sensorChanged(value)
    if (value > 0) then
        sensorId = sensorsAvailable[value].id
        paramId = sensorsAvailable[value].param
        system.pSave("sensorId", sensorId)
        system.pSave("paramId", paramId)
    end
end

-- Initialise form (configuration)
local function initForm(formId)
    local list = {}
    local curIndex = -1

    -- render form
    sensorId = system.pLoad("sensorId", 0)
    paramId = system.pLoad("paramId", 0)
    sensorLabel = system.pLoad("sensorLabel", "Label")

    sensorsAvailable = {}
    local available = system.getSensors();
    local list = {}
    local curIndex = -1
    local descr = ""
    for index,sensor in ipairs(available) do
      if (sensor.param == 0) then
        descr = sensor.label
      else
        list[#list+1] = string.format("%s - %s [%s]", descr, sensor.label, sensor.unit)
        sensorsAvailable[#sensorsAvailable+1] = sensor
        if (sensor.id == sensorId and sensor.param == paramId) then
          curIndex = #sensorsAvailable
        end
      end
    end

    form.addRow(2)
    form.AddLabel({label = lang.selectSensor, width = 120})
    form.AddSelectBox(list, curIndex, true, sensorChanged, {width = 190})
end

local val1 = 0
local dir1 = 1
local instances = {
    { 0, 0 },
    { 1, 0 },
    { 2, 0 },
    { 3, 0 },
    { 0, 0 },
    { 1, 0 },
    { 2, 0 },
    { 3, 0 }
}
local function displayGauges1(width, height)
    for ix, iy in pairs(instances) do 
    end
    local szX = width / 4
    local szY = height / 2
    primitives.renderGauge2(ren, 90, 330, 0, 0, szX, szY, val1, 200, "%.0f", "RPM")
    primitives.renderGauge2(ren, 90, 330, szX, 0, szX, szY, val1, 200, "%.1f", "Thr%")
    primitives.renderGauge2(ren, 90, 330, szX * 2, 0, szX, szY, val1, 200, "%.1fV", "ESC V")

    primitives.renderGauge2(ren, 90, 330, 0, szY, szX, szY, val1, 200, "%.1f°C", "ESC Temp")
    primitives.renderGauge2(ren, 90, 330, szX, szY, szX, szY, val1, 200, "%.1fV", "BEC V")
    primitives.renderGauge2(ren, 90, 330, szX * 2, szY, szX, szY, val1, 200, "%.1fA", "ESC A")
    primitives.renderCellGraph(ren, szX * 3, 0, szX / 2, szY * 2, {
        3.85, 4, 3.699, 3.78, 3.77, 3.6
    }, 3.8)
    primitives.renderBatteryGauge(ren, szX * 3 + szX / 2, 0, szX / 2, szY * 2, val1, 200)

    val1 = val1 + 1.25 * dir1
    if (dir1 == 1 and val1 > 200) then
        val1 = 200
        dir1 = -1
    else 
        if (dir1 == -1 and val1 < 0) then
            val1 = 0
            dir1 = 1
        end
    end
end

-- Application initialization.
local function init(code)
    print ("Application initialized")

    system.registerTelemetry(1, "GaugesFs1", 4, displayGauges1) 
end
   
-- Loop function is called in regular intervals
local function loop()
end

-- Application interface
setLanguage()
return {init = init, loop = loop, author = "Marc Marais", version = "0.1", name = "Hud Gauges"}
