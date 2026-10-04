#include "stdafx.h"
#include "CPUUsage.h"
#include "Common.h"
#include "TrafficMonitor.h"
#include <powerbase.h>
#include <sysinfoapi.h>


///////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////
CPdhCPUUsage::CPdhCPUUsage(LPCTSTR counter_path)
    : CPdhQuery(counter_path)
{
}

bool CPdhCPUUsage::GetCPUUsage(int& cpu_usage)
{
    double value{};
    if (QueryValue(value))
    {
        cpu_usage = static_cast<int>(value + 0.5); // 작업관리자와 동일하게 반올림
        if (cpu_usage > 100)
            cpu_usage = 100;
        return true;
    }
    return false;
}

///////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////
CCPUUsage::CCPUUsage()
    : m_pdh_time(_T("\\Processor Information(_Total)\\% Processor Time"))
    , m_pdh_utility(_T("\\Processor Information(_Total)\\% Processor Utility"))
    , m_pdh_perf(_T("\\Processor Information(_Total)\\% Processor Performance"))
{
}

/// method: 0=CPU 시간(GetSystemTimes), 1=PDH Processor Time, 2=PDH Processor Utility, 3=Utility÷Performance(클럭 보정)
int CCPUUsage::GetCpuUsage(int method)
{
    int cpu_usage{};
    if (method == 0)
    {
        cpu_usage = GetCpuUsageByGetSystemTimes();
    }
    else if (method == 3)
    {
        // Utility는 기본 클럭 대비 값이므로 현재 클럭 비율(Performance)로 나누어 정규화
        double utility{}, perf{};
        if (m_pdh_utility.GetValue(utility) && m_pdh_perf.GetValue(perf) && perf > 0)
            cpu_usage = (std::min)(100, static_cast<int>(utility * 100 / perf + 0.5));
        else
            cpu_usage = GetCpuUsageByGetSystemTimes();
    }
    else
    {
        //如果通过pdh获取CPU利用率失败，采用GetSystemTimes获取
        CPdhCPUUsage& pdh = (method == 2) ? m_pdh_utility : m_pdh_time;
        if (!pdh.GetCPUUsage(cpu_usage))
        {
            cpu_usage = GetCpuUsageByGetSystemTimes();
            //写入日志
            //static bool write_log = false;
            //if (!write_log)
            //{
            //    CString str_log = CCommon::LoadTextFormat(IDS_GET_CPU_USAGE_BY_PDH_FAILED_LOG, { fullCounterPath });
            //    CCommon::WriteLog(str_log, theApp.m_log_path.c_str());
            //    write_log = true;
            //}
        }
    }
    return cpu_usage;
}

int CCPUUsage::GetCpuUsageByGetSystemTimes()
{
    int cpu_usage{};
    FILETIME idleTime;
    FILETIME kernelTime;
    FILETIME userTime;
    GetSystemTimes(&idleTime, &kernelTime, &userTime);

    __int64 idle = CCommon::CompareFileTime2(m_preidleTime, idleTime);
    __int64 kernel = CCommon::CompareFileTime2(m_prekernelTime, kernelTime);
    __int64 user = CCommon::CompareFileTime2(m_preuserTime, userTime);

    if (kernel + user == 0)
    {
        cpu_usage = 0;
    }
    else
    {
        //（总的时间-空闲时间）/总的时间=占用cpu的时间就是使用率
        cpu_usage = static_cast<int>(abs((kernel + user - idle) * 100 / (kernel + user)));
    }
    m_preidleTime = idleTime;
    m_prekernelTime = kernelTime;
    m_preuserTime = userTime;

    return cpu_usage;
}
