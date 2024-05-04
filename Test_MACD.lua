function OnInit()
    Class_code =  "SPBFUT"
    Client_code = "567250R7WF1"                     -- Код клиента
    Firmid = "MC0061900000"  
    Tag = "EQTV"
    Cur_code = "SUR"                                -- Код валюты
    Trdaccid = "76805ks"                            -- Торговый счет
    Sec_code = "CNYRUBF"                            -- Торговый инструмент
    INTERVAL_H4 = 240                              -- Дневной интервал
    Period_Slow = 26                                -- Период сглаживания медленной EMA
    Period_Fast = 12                                 -- Период сглаживания быстрой EMA
    SDiapazon_H4 = 0
    log =  getScriptPath().."\\".."Save_one.txt"
end

function Log(str)                               -- Запись логов работы 
    -------------------------------------------------------------------------------------
           
           lg = io.open(log, "a+") 
           lg:write(tostring(str).."\n") 
           lg:flush() 
           lg:close()      
end
-----------------------------------------------------------------------------------------------
function MACD_()
    Ema_Fast = {}
    Ema_Slow = {}
    MACD = {}
    DS_H4, Error = CreateDataSource(Class_code, Sec_code, INTERVAL_H4)          -- Получение таблицы данных по D1
    while (DS_H4:Size() == nil or DS_H4:Size() == 0) do                 -- Проверка получены ли данные
       if Error ~= nil or Error ~="" then 
        message("Ошибка подключения к графику: "..Error) 
        break end
     
          sleep(100)
        end
    
    message(" Данные получены")
    DS_H4:SetEmptyCallback()                                                     -- Подписка на автоматическое получение обновленных данных (Для D1 актуально?)
    local Delita_price_H4 = 0 
    local Highprice_H4 = 0
    local Lowprice_H4 = 0
    local Data_H4 = {}
    local Candles_H4 = DS_H4:Size()                 -- Кол-во свечей по которым получены данные
    
    Ema_Slow[1] = DS_H4:C(1) 
    Ema_Fast[1] = DS_H4:C(1)
    A_Fast = 2/(Period_Fast+1)
    A_Slow = 2/(Period_Slow+1)
    for i = 2, Candles_H4 do
        Highprice_H4 = DS_H4:H(i)                   -- High
        Lowprice_H4 = DS_H4:L(i)                    -- Low
        Data_H4 = DS_H4:T(i)
            Ema_Slow[i] = DS_H4:C(i)
            Ema_Fast[i] = DS_H4:C(i)
          
            Ema_Slow[i] =  DS_H4:C(i)*A_Slow + Ema_Slow[i-1]*(1 - A_Slow)    -- Расчет медленной EMA
           
            Ema_Fast[i] =  DS_H4:C(i)*A_Fast + Ema_Fast[i-1]*(1 - A_Fast)    --Расчет быстрой EMA
           
            Delita_price_H4 = Delita_price_H4 + math.abs(Highprice_H4 -Lowprice_H4)    -- Расчет суммы всех дневных диапазонов
       
        if i >= Candles_H4 - Period_Slow then                                               --  Оставляем в памяти последние 22 значения
            MACD[i-Period_Slow] = {}
            MACD[i-Period_Slow].macd = tonumber(string.format("%.6f", (Ema_Fast[i] - Ema_Slow[i])))       -- Расчет MACD
            MACD[i-Period_Slow].slow = tonumber(string.format("%.6f", Ema_Slow[i] ))
            MACD[i-Period_Slow].fast = tonumber(string.format("%.6f", Ema_Fast[i] ))
            MACD[i-Period_Slow].data = tostring(Data_H4.day..' число '..Data_H4.month.." мес "..Data_H4.hour.." час "..Data_H4.min.." мин")
            Str = tostring(MACD[i-Period_Slow].data.." -дата и время".."\n"..
            MACD[i-Period_Slow].macd.." - MACD  "..MACD[i-Period_Slow].fast.." - fast  "..MACD[i-Period_Slow].slow.." - slow")
           Log(Str)
        end  
        SDiapazon_H4 = Delita_price_H4/Candles_H4                        -- Расчет среднедневного диапазона
    end
   
end

  ------------------------------------------------------
  function OnStop()                           -- Функция остановки бота по нажатию кнопки "Stop"
    Log("Остановка скрипта - Stop")
    is_run = false
    
    return 2000   
  end

  function main()
     
    MACD_()
   
  end