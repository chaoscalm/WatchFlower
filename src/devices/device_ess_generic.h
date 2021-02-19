/*!
 * This file is part of WatchFlower.
 * COPYRIGHT (C) 2020 Emeric Grange - All Rights Reserved
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * \date      2021
 * \author    Emeric Grange <emeric.grange@gmail.com>
 */

#ifndef DEVICE_ESS_GENERIC_H
#define DEVICE_ESS_GENERIC_H
/* ************************************************************************** */

#include "device_sensor.h"

#include <QObject>
#include <QList>

#include <QBluetoothDeviceInfo>
#include <QLowEnergyController>

/* ************************************************************************** */

/*!
 * Generic implementation for Bluetooth Low Energy "Environmental Sensing Service".
 *
 * Protocol infos:
 * - WatchFlower/docs/ess-ble-api.md
 * - https://www.bluetooth.com/specifications/specs/environmental-sensing-profile-1-0/
 * - https://www.bluetooth.com/specifications/specs/environmental-sensing-service-1-0/
 * - https://www.bluetooth.com/specifications/assigned-numbers/environmental-sensing-service-characteristics/
 */
class DeviceEssGeneric: public DeviceSensor
{
    Q_OBJECT

public:
    DeviceEssGeneric(QString &deviceAddr, QString &deviceName, QObject *parent = nullptr);
    DeviceEssGeneric(const QBluetoothDeviceInfo &d, QObject *parent = nullptr);
    ~DeviceEssGeneric();

private:
    // QLowEnergyController related
    void serviceScanDone();
    void addLowEnergyService(const QBluetoothUuid &uuid);
    void serviceDetailsDiscovered_ess(QLowEnergyService::ServiceState newState);
    void serviceDetailsDiscovered_battery(QLowEnergyService::ServiceState newState);

    QLowEnergyService *serviceEnvironmentalSensing = nullptr;
    QLowEnergyService *serviceBattery = nullptr;
};

/* ************************************************************************** */
#endif // DEVICE_ESS_GENERIC_H
