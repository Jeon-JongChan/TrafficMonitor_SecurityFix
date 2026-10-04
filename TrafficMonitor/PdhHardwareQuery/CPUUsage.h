#pragma once
#include <Pdh.h>
#include <PdhMsg.h>
#include "PdhQuery.h"

class CPdhCPUUsage : public CPdhQuery
{
public:
    CPdhCPUUsage(LPCTSTR counter_path);

    ~CPdhCPUUsage()
    {
    }

    bool GetCPUUsage(int& cpu_usage);

};

//////////////////////////////////////////////////////////////////////////////////
class CCPUUsage
{
public:
    CCPUUsage();

    ~CCPUUsage()
    {}

    int GetCpuUsage(int method);

private:
    int GetCpuUsageByGetSystemTimes();

private:

    FILETIME m_preidleTime{};
    FILETIME m_prekernelTime{};
    FILETIME m_preuserTime{};

    CPdhCPUUsage m_pdh_time;     // % Processor Time
    CPdhCPUUsage m_pdh_utility;  // % Processor Utility
};
