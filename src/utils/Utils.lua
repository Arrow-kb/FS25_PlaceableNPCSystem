function Utils.formatTemperature()
    return g_i18n:formatTemperature(g_currentMission.environment.weather:getCurrentTemperature(), 0, false)
end