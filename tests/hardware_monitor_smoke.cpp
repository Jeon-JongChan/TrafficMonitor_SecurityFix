#include "OpenHardwareMonitor/OpenHardwareMonitorApi.h"
#include <cmath>
#include <iostream>

/// <summary>실제 래퍼의 로딩, 빈 센서 처리와 비활성화 후 캐시 초기화를 확인한다.</summary>
int main()
{
    auto monitor = OpenHardwareMonitorApi::CreateInstance();
    if (!monitor)
    {
        std::wcerr << OpenHardwareMonitorApi::GetErrorMessage() << std::endl;
        return 1;
    }
    monitor->SetCpuEnable(true);
    monitor->SetGpuEnable(true);
    monitor->SetHddEnable(true);
    monitor->SetMainboardEnable(true);
    monitor->GetHardwareInfo();
    // PawnIO가 없어도 빈 센서를 NaN으로 바꾸거나 초기화 예외를 숨기면 실패한다.
    if (!OpenHardwareMonitorApi::GetErrorMessage().empty() || !std::isfinite(monitor->CpuFreq()))
        return 2;
    for (const auto& sensor : monitor->AllCpuTemperature())
        if (!std::isfinite(sensor.second))
            return 3;

    monitor->SetCpuEnable(false);
    monitor->GetHardwareInfo();
    if (!monitor->AllCpuTemperature().empty() || monitor->CpuFreq() != -1)
        return 4;
    std::cout << "PawnIO 설치 상태: " << OpenHardwareMonitorApi::IsPawnIoInstalled() << std::endl;
    return 0;
}
