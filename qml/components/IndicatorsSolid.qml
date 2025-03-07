import QtQuick
import QtQuick.Controls

import ComponentLibrary

Item {
    id: indicatorsSolid
    anchors.left: parent.left
    anchors.right: parent.right
    height: columnData.height + 24
    z: 5

    property string colorBackground: {
        if (headerUnicolor) return Theme.colorHeaderHighlight
        if (uiMode === 2) return Theme.colorBackground
        return Theme.colorForeground
    }

    property int legendWidth: 80

    ////////////////////////////////////////////////////////////////////////////

    function loadIndicators() {
        if (typeof currentDevice === "undefined" || !currentDevice) return
        if (!currentDevice.isPlantSensor) return
        //console.log("DevicePlantSensorData // updateData() >> " + currentDevice)

        soil_moisture.animated = false
        soil_conductivity.animated = false
        soil_temperature.animated = false
        temp.animated = false
        humi.animated = false
        lumi.animated = false
        water_tank.animated = false

        updateLegendSize()
        updateData()

        soil_moisture.animated = true
        soil_conductivity.animated = true
        soil_temperature.animated = true
        temp.animated = true
        humi.animated = true
        lumi.animated = true
        water_tank.animated = true
    }

    function updateLegendSize() {
        legendWidth = 0
        if (legendWidth < soil_moisture.legendContentWidth) legendWidth = soil_moisture.legendContentWidth
        if (legendWidth < soil_conductivity.legendContentWidth) legendWidth = soil_conductivity.legendContentWidth
        if (legendWidth < soil_temperature.legendContentWidth) legendWidth = soil_temperature.legendContentWidth
        if (legendWidth < temp.legendContentWidth) legendWidth = temp.legendContentWidth
        if (legendWidth < humi.legendContentWidth) legendWidth = humi.legendContentWidth
        if (legendWidth < lumi.legendContentWidth) legendWidth = lumi.legendContentWidth
        if (legendWidth < water_tank.legendContentWidth) legendWidth = water_tank.legendContentWidth
    }

    function tempHelper(tempDeg) {
        return (settingsManager.tempUnit === "F") ? UtilsNumber.tempCelsiusToFahrenheit(tempDeg) : tempDeg
    }

    function updateData() {
        if (typeof currentDevice === "undefined" || !currentDevice) return
        if (!currentDevice.isPlantSensor) return
        //console.log("DevicePlantSensorData // updateData() >> " + currentDevice)

        // Has data? always display them
        if (currentDevice.isDataToday()) {
            //var hasHygro = (currentDevice.soilMoisture > 0 || currentDevice.soilConductivity > 0) ||
            //               (currentDevice.hasDataNamed("soilMoisture") || currentDevice.hasDataNamed("soilConductivity"))

            soil_moisture.visible = currentDevice.hasSoilMoistureSensor
            soil_conductivity.visible = currentDevice.hasSoilConductivitySensor
            soil_temperature.visible = currentDevice.hasSoilTemperatureSensor
            temp.visible = currentDevice.hasTemperatureSensor
            humi.visible = currentDevice.hasHumiditySensor
            lumi.visible = currentDevice.hasLuminositySensor
            water_tank.visible = currentDevice.hasWaterLevelSensor
        } else {
            soil_moisture.visible = currentDevice.hasSoilMoistureSensor
            soil_conductivity.visible = currentDevice.hasSoilConductivitySensor
            soil_temperature.visible = currentDevice.hasSoilTemperatureSensor
            temp.visible = currentDevice.hasTemperatureSensor
            humi.visible = currentDevice.hasHumiditySensor
            lumi.visible = currentDevice.hasLuminositySensor
            water_tank.visible = currentDevice.hasWaterLevelSensor
        }

        resetDataBars()
    }

    function updateDataBars(soilM, soilC, soilT, tempD, humiD, lumiD) {
        soil_moisture.value = soilM
        soil_conductivity.value = soilC
        soil_temperature.value = tempHelper(soilT)
        temp.value = tempHelper(tempD)
        humi.value = humiD
        lumi.value = lumiD
        water_tank.value = -99

        soil_moisture.warning = false
        temp.warning = false
        water_tank.warning = false
    }

    function resetDataBars() {
        soil_moisture.value = currentDevice.soilMoisture
        soil_conductivity.value = currentDevice.soilConductivity
        soil_temperature.value = tempHelper(currentDevice.soilTemperature)
        temp.value = currentDevice.temperature
        humi.value = currentDevice.humidity
        lumi.value = currentDevice.luminosityLux
        water_tank.value = currentDevice.waterTankLevel

        soil_moisture.warning = true
        temp.warning = true
        water_tank.warning = true
    }

    ////////////////////////////////////////////////////////////////////////////

    Column {
        id: columnData
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 0

        spacing: 14

        ////////

        DataBarSolid {
            id: soil_moisture
            anchors.left: parent.left
            anchors.right: parent.right

            legend: qsTr("Moisture")
            legendWidth: indicatorsSolid.legendWidth
            suffix: "%"
            warning: true
            colorForeground: Theme.colorBlue
            colorBackground: indicatorsSolid.colorBackground

            value: currentDevice.soilMoisture
            valueMin: 0
            valueMax: settingsManager.dynaScale ? Math.ceil(currentDevice.hygroMax*1.10) : 50
            limitMin: currentDevice.soilMoisture_limitMin
            limitMax: currentDevice.soilMoisture_limitMax
        }

        ////////

        DataBarSolid {
            id: soil_conductivity
            anchors.left: parent.left
            anchors.right: parent.right

            legend: qsTr("Fertility")
            legendWidth: indicatorsSolid.legendWidth
            suffix: " " + qsTr("µS/cm")
            colorForeground: Theme.colorRed
            colorBackground: indicatorsSolid.colorBackground

            value: currentDevice.soilConductivity
            valueMin: 0
            valueMax: settingsManager.dynaScale ? Math.ceil(currentDevice.conduMax*1.10) : 2000
            limitMin: currentDevice.soilConductivity_limitMin
            limitMax: currentDevice.soilConductivity_limitMax
        }

        ////////

        DataBarSolid {
            id: soil_temperature
            anchors.left: parent.left
            anchors.right: parent.right

            legend: qsTr("Soil temp.")
            legendWidth: indicatorsSolid.legendWidth
            suffix: "°" + settingsManager.tempUnit
            colorForeground: Qt.darker(Theme.colorGreen, 1.1)
            colorBackground: indicatorsSolid.colorBackground

            floatprecision: 1
            value: tempHelper(currentDevice.soilTemperature)
            valueMin: tempHelper(settingsManager.dynaScale ? Math.floor(currentDevice.tempMin*0.80) : tempHelper(0))
            valueMax: tempHelper(settingsManager.dynaScale ? (currentDevice.tempMax*1.20) : tempHelper(40))
            limitMin: 0
            limitMax: 0
        }

        ////////

        DataBarSolid {
            id: water_tank
            anchors.left: parent.left
            anchors.right: parent.right

            legend: qsTr("Water tank")
            legendWidth: indicatorsSolid.legendWidth
            suffix: "L"
            colorForeground: Qt.lighter(Theme.colorBlue, 1.1)
            colorBackground: indicatorsSolid.colorBackground

            floatprecision: 1
            value: currentDevice.waterTankLevel
            valueMin: 0
            valueMax: currentDevice.waterTankCapacity
            limitMin: currentDevice.waterTankCapacity * 0.15
            limitMax: currentDevice.waterTankCapacity
        }

        ////////

        DataBarSolid {
            id: temp
            anchors.left: parent.left
            anchors.right: parent.right

            legend: qsTr("Temperature")
            legendWidth: indicatorsSolid.legendWidth
            warning: true
            suffix: "°" + settingsManager.tempUnit
            colorForeground: Theme.colorGreen
            colorBackground: indicatorsSolid.colorBackground

            floatprecision: 1
            value: currentDevice.temperature
            valueMin: tempHelper(settingsManager.dynaScale ? Math.floor(currentDevice.tempMin*0.80) : tempHelper(0))
            valueMax: tempHelper(settingsManager.dynaScale ? (currentDevice.tempMax*1.20) : tempHelper(40))
            limitMin: tempHelper(currentDevice.temperature_limitMin)
            limitMax: tempHelper(currentDevice.temperature_limitMax)
        }

        ////////

        DataBarSolid {
            id: humi
            anchors.left: parent.left
            anchors.right: parent.right

            legend: qsTr("Humidity")
            legendWidth: indicatorsSolid.legendWidth
            suffix: "%"
            colorForeground: Theme.colorBlue
            colorBackground: indicatorsSolid.colorBackground

            value: currentDevice.humidity
            valueMin: 0
            valueMax: 100
            limitMin: 0
            limitMax: 100
        }

        ////////

        DataBarSolid {
            id: lumi
            anchors.left: parent.left
            anchors.right: parent.right

            legend: qsTr("Luminosity")
            legendWidth: indicatorsSolid.legendWidth
            suffix: " " + qsTr("lux")
            colorForeground: Theme.colorYellow
            colorBackground: indicatorsSolid.colorBackground

            value: currentDevice.luminosityLux
            valueMin: 0
            valueMax: settingsManager.dynaScale ? Math.ceil(currentDevice.luxMax*1.10) : 10000
            limitMin: currentDevice.luminosityLux_limitMin
            limitMax: currentDevice.luminosityLux_limitMax
        }

        ////////
    }
}
