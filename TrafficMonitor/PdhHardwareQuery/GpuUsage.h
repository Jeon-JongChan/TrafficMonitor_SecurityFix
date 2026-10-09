#pragma once
#include "PdhQuery.h"

/// <summary>
/// PDH 성능 카운터를 통한 GPU 이용률 모니터링 클래스
/// </summary>
class CPdhGPUUsage : public CPdhQuery
{
public:
    /// <summary>CPdhGPUUsage 생성자</summary>
    CPdhGPUUsage();
    /// <summary>CPdhGPUUsage 소멸자</summary>
    virtual ~CPdhGPUUsage();

    /// <summary>
    /// GPU 이용률을 획득합니다 (0-100%).
    /// 작업 관리자와 동일하게 모든 GPU 엔진 중 최대 부하 엔진 기준(정확도 모드)으로 산출합니다.
    /// </summary>
    /// <param name="usage">획득된 GPU 이용률 출력 변수</param>
    /// <returns>성공 여부</returns>
    bool GetGpuUsage(/*out*/ int& usage);
};
