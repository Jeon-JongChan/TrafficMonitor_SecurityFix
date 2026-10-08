#using <LibreHardwareMonitorLib.dll>
#using <HidSharp.dll>
#include <memory>
#include <map>
#include <string>
#include <cassert>

// 실제 수집 함수를 검사하되 제품 코드에는 테스트 전용 공개 API를 추가하지 않는다.
#define private public
#include "../OpenHardwareMonitorApi/OpenHardwareMonitorImp.h"
#undef private
#include "../OpenHardwareMonitorApi/OpenHardwareMonitorImp.cpp"
#include "../OpenHardwareMonitorApi/UpdateVisitor.cpp"

/// <summary>라이브러리의 기본 설정 구현을 검사에서도 재사용한다.</summary>
ISettings^ CreateSettings()
{
    return safe_cast<ISettings^>(Activator::CreateInstance(Hardware::typeid->Assembly->GetType("LibreHardwareMonitor.Hardware.Computer+Settings"), true));
}

/// <summary>내부 센서 클래스의 실측값을 검사 조건에 맞게 설정한다.</summary>
void SetSensorValue(Object^ sensor, Nullable<float> value)
{
    sensor->GetType()->GetProperty("Value")->SetValue(sensor, value, nullptr);
}

/// <summary>가상 DIMM의 라이브러리 식별자를 생성한다.</summary>
LibreHardwareMonitor::Hardware::Identifier^ CreateIdentifier()
{
    return gcnew LibreHardwareMonitor::Hardware::Identifier(gcnew array<String^>{ "memory", "dimm", "0" });
}

/// <summary>실측값과 온도 한계값을 함께 제공하는 가상 DIMM이다.</summary>
ref class TestDimm sealed : Hardware
{
public:
    /// <summary>온도 센서가 포함된 가상 RAM 하드웨어를 생성한다.</summary>
    TestDimm() : Hardware("테스트 DIMM", CreateIdentifier(), CreateSettings())
    {
        Measured = AddTemperature("DIMM #0", 0, 42.0f);
        AddTemperature("Temperature Sensor Resolution", 1, 0.25f);
        AddTemperature("Thermal Sensor High Limit", 3, 85.0f);
        AddTemperature("Thermal Sensor Critical Limit", 4, 100.0f);
    }

    /// <summary>검사 대상인 RAM 하드웨어 유형을 반환한다.</summary>
    virtual property LibreHardwareMonitor::Hardware::HardwareType HardwareType
    {
        LibreHardwareMonitor::Hardware::HardwareType get() override { return LibreHardwareMonitor::Hardware::HardwareType::Memory; }
    }

    /// <summary>가상 센서값은 검사 코드가 직접 설정하므로 갱신하지 않는다.</summary>
    virtual void Update() override {}

    Object^ Measured;

private:
    /// <summary>지정한 인덱스와 값을 가진 온도 센서를 등록한다.</summary>
    Object^ AddTemperature(String^ name, int index, float value)
    {
        Object^ sensor = Activator::CreateInstance(Hardware::typeid->Assembly->GetType("LibreHardwareMonitor.Hardware.Sensor"),
            gcnew array<Object^>{ name, index, SensorType::Temperature, this, CreateSettings() });
        SetSensorValue(sensor, value);
        ActivateSensor(safe_cast<ISensor^>(sensor));
        return sensor;
    }
};

/// <summary>RAM 실측값 선택, 결측값 처리 및 캐시 초기화를 검증한다.</summary>
int main()
{
    using namespace OpenHardwareMonitorApi;
    MonitorGlobal::Instance()->Init();
    COpenHardwareMonitor monitor;
    TestDimm^ dimm = gcnew TestDimm();
    float temperature = -1;
    assert(monitor.GetHardwareTemperature(dimm, temperature) && temperature == 42.0f);

    // 실측값이 없으면 한계값으로 대체하지 않는다.
    SetSensorValue(dimm->Measured, Nullable<float>());
    assert(!monitor.GetHardwareTemperature(dimm, temperature) && temperature == -1);
    SetSensorValue(dimm->Measured, Single::NaN);
    assert(!monitor.GetHardwareTemperature(dimm, temperature) && temperature == -1);
    SetSensorValue(dimm->Measured, Single::PositiveInfinity);
    assert(!monitor.GetHardwareTemperature(dimm, temperature) && temperature == -1);
    SetSensorValue(dimm->Measured, -2.0f);
    assert(!monitor.GetHardwareTemperature(dimm, temperature) && temperature == -1);
    SetSensorValue(dimm->Measured, 0.0f);
    assert(monitor.GetHardwareTemperature(dimm, temperature) && temperature == 0);

    monitor.m_memory_temperature = 42.0f;
    monitor.ResetAllValues();
    assert(monitor.MemoryTemperature() == -1);
    monitor.m_memory_temperature = 42.0f;
    monitor.SetMemoryEnable(false);
    assert(monitor.MemoryTemperature() == -1);
    return 0;
}
