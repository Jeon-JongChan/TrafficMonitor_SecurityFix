#include "stdafx.h"
#include "GpuUsage.h"

///////////////////////////////////////////////////////////////////////////////////////////
// CPdhGPUUsage 구현
///////////////////////////////////////////////////////////////////////////////////////////

/// <summary>
/// 작업 관리자와 동일한 전체 GPU 엔진 카운터 경로로 초기화합니다.
/// </summary>
CPdhGPUUsage::CPdhGPUUsage()
    : CPdhQuery(_T("\\GPU Engine(*)\\Utilization Percentage"))
{
}

CPdhGPUUsage::~CPdhGPUUsage()
{
}

/// <summary>
/// GPU 이용률을 계산하여 반환합니다.
/// Windows 작업 관리자와 동일하게 엔진 종류별(3D, VideoDecode, Compute 등)로 합산 후 최대값을 선택합니다.
/// </summary>
bool CPdhGPUUsage::GetGpuUsage(int& usage)
{
    if (isInitialized)
    {
        std::vector<CounterValueItem> valueItems;
        if (QueryValues(valueItems))
        {
            if (!valueItems.empty())
            {
                // 엔진 타입별 합산 후 최대값 선택
                std::map<std::wstring, double> gpu_usage_map;
                for (const auto& item : valueItems)
                {
                    std::wstring item_name = item.name;
                    size_t index = item.name.rfind(L'_');
                    if (index != std::wstring::npos)
                        item_name = item.name.substr(index + 1);
                    gpu_usage_map[item_name] += item.value;
                }
                double max_value = 0;
                for (const auto& item : gpu_usage_map)
                {
                    if (item.second > max_value)
                        max_value = item.second;
                }
                usage = static_cast<int>(max_value + 0.5);
                usage = min(max(usage, 0), 100);
                return true;
            }
        }
    }

    return false;
}
