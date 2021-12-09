import QtQuick 2.15
import QtQuick.Controls 2.15

import ThemeEngine 1.0

Item {
    id: devicePlantSensor
    width: 450
    height: 700

    property var currentDevice: null

    Connections {
        target: currentDevice

        function onStatusUpdated() {
            plantSensorData.updateHeader()
        }
        function onSensorUpdated() {
            plantSensorData.updateHeader()
            plantSensorLimits.updateHeader()
        }
        function onSensorsUpdated() {
            plantSensorData.updateHeader()
            plantSensorLimits.updateHeader()
        }
        function onRefreshUpdated() {
            plantSensorData.resetHistoryMode()
            plantSensorData.updateGraph()
            plantSensorHistory.updateData()
        }
        function onHistoryUpdated() {
            plantSensorData.updateGraph()
            plantSensorHistory.updateData()
        }
    }

    Connections {
        target: settingsManager

        function onBigIndicatorChanged() {
            plantSensorData.reloadIndicators()
        }
        function onAppLanguageChanged() {
            plantSensorData.updateStatusText()
            plantSensorData.updateLegendSizes()
        }
        function onGraphHistoryChanged() {
            plantSensorHistory.updateHistoryMode()
        }
    }

    Connections {
        target: ThemeEngine
        function onCurrentThemeChanged() {
            plantSensorData.updateHeader()
            plantSensorHistory.updateHeader()
            plantSensorHistory.updateColors()
            plantSensorLimits.updateHeader()
        }
    }

    Connections {
        target: appHeader

        // desktop only
        function onDeviceDataButtonClicked() {
            appHeader.setActiveDeviceData()
            sensorPages.currentIndex = 0
        }
        function onDeviceHistoryButtonClicked() {
            appHeader.setActiveDeviceHistory()
            sensorPages.currentIndex = 1
        }
        function onDeviceSettingsButtonClicked() {
            appHeader.setActiveDeviceSettings()
            sensorPages.currentIndex = 2
        }
    }

    Connections {
        target: tabletMenuDevice

        // mobile only
        function onDeviceDataButtonClicked() {
            tabletMenuDevice.setActiveDeviceData()
            sensorPages.currentIndex = 0
        }
        function onDeviceHistoryButtonClicked() {
            tabletMenuDevice.setActiveDeviceHistory()
            sensorPages.currentIndex = 1
        }
        function onDeviceSettingsButtonClicked() {
            tabletMenuDevice.setActiveDeviceSettings()
            sensorPages.currentIndex = 2
        }
    }

    Keys.onPressed: {
        if (event.key === Qt.Key_Left) {
            event.accepted = true
            if (sensorPages.currentIndex > 0)
                sensorPages.currentIndex--
        } else if (event.key === Qt.Key_Right) {
            event.accepted = true
            if (sensorPages.currentIndex+1 < sensorPages.count)
                sensorPages.currentIndex++
        } else if (event.key === Qt.Key_F5) {
            event.accepted = true
            deviceManager.updateDevice(currentDevice.deviceAddress)
        } else if (event.key === Qt.Key_Backspace) {
            event.accepted = true
            appWindow.backAction()
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    function isHistoryMode() {
        return (plantSensorData.isHistoryMode() || plantSensorHistory.isHistoryMode())
    }
    function resetHistoryMode() {
        plantSensorData.resetHistoryMode()
        plantSensorHistory.resetHistoryMode()
    }

    function loadDevice(clickedDevice) {
        if (typeof clickedDevice === "undefined" || !clickedDevice) return
        if (!clickedDevice.hasSoilMoistureSensor) return
        if (clickedDevice === currentDevice) return

        currentDevice = clickedDevice
        //console.log("DevicePlantSensor // loadDevice() >> " + currentDevice)

        sensorPages.disableAnimation()
        sensorPages.currentIndex = 0
        sensorPages.interactive = isPhone
        sensorPages.enableAnimation()

        plantSensorData.loadData()
        plantSensorHistory.updateHeader()
        plantSensorHistory.loadData()
        plantSensorLimits.updateHeader()
        plantSensorLimits.updateLimits()

        if (isMobile) tabletMenuDevice.setActiveDeviceData()
        if (isDesktop) appHeader.setActiveDeviceData()
    }

    ////////////////////////////////////////////////////////////////////////////

    ItemBannerSync {
        id: bannerSync
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        z: 5
    }

    Item {
        anchors.top: parent.top
        anchors.topMargin: bannerSync.visible ? bannerSync.height : 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        SwipeView {
            id: sensorPages
            anchors.fill: parent

            interactive: isPhone

            currentIndex: 0
            onCurrentIndexChanged: {
                if (isDesktop) {
                    if (sensorPages.currentIndex === 0)
                        appHeader.setActiveDeviceData()
                    else if (sensorPages.currentIndex === 1)
                        appHeader.setActiveDeviceHistory()
                    else if (sensorPages.currentIndex === 2)
                        appHeader.setActiveDeviceSettings()
                } else {
                    if (sensorPages.currentIndex === 0)
                        tabletMenuDevice.setActiveDeviceData()
                    else if (sensorPages.currentIndex === 1)
                        tabletMenuDevice.setActiveDeviceHistory()
                    else if (sensorPages.currentIndex === 2)
                        tabletMenuDevice.setActiveDeviceSettings()
                }
            }

            function enableAnimation() {
                contentItem.highlightMoveDuration = 333
            }
            function disableAnimation() {
                contentItem.highlightMoveDuration = 0
            }

            DevicePlantSensorData {
                clip: false
                id: plantSensorData
            }
            DevicePlantSensorHistory {
                clip: true
                id: plantSensorHistory
            }
            DevicePlantSensorLimits {
                clip: false
                id: plantSensorLimits
            }
        }
    }
}
