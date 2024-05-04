----  Простой робот по индикаторам тех анализа  ----
-----------------------------------------------
function OnInit()  -- Первичная инициализация данных
    Name_Bot = "Бот на скользящих средних"          -- Наименование робота
    Version = " 1.0"                                -- Номер версии бота
    Sec_code = ""                                   -- Наименование торгового тнструмента
    Class_code =  "SPBFUT"
    Client_code = "567250R7WF1"                     -- Код клиента
    Firmid = "MC0061900000"  
    Tag = "EQTV"
    Cur_code = "SUR"                                -- Код валюты
    Trdaccid = "76805ks"                            -- Торговый счет
    Status, Connect, Session_status = 0, 0, 0       -- первичная инициализация
    Stop = "off"                                    -- Режим работы робота пауза/работа
    Depo = getMoney(Client_code, Firmid, Tag, Cur_code).money_limit_available  -- Депозит
    Interval_M60 = 60                                 -- 60  Минут
    Interval_M15 = 15                                  -- 5 Мин
    INTERVAL_H4 = 240                              -- Дневной интервал
    Period_Slow = 26                                -- Период сглаживания медленной EMA
    Period_Fast = 12                                 -- Период сглаживания быстрой EMA
    SDiapazon_H4 = 0                 
    Risk = 2
    Open_poz = 0                                        -- открытые позиции 
    log =  getScriptPath().."\\".."Save_one.txt"        -- Файл записи логов работы
    Tabl_sort = {}                                      -- Отсортированная таблица данных
end

function Status() --Функция проверки состояния подключения 
    local connect = tostring(math.ceil( isConnected() ))
    local status = tostring(math.ceil(getParamEx(Class_code, Sec_code, "STAtUS").param_value) or 0)
    local session_status = tostring(math.ceil(getFuturesHolding(Firmid,Trdaccid,Sec_code, 0).session_status) or 0)
     
end




-------------------------------------------------------------------------------------
function Log(str)                               -- Запись логов работы 
-------------------------------------------------------------------------------------
       
       lg = io.open(log, "a+") 
       lg:write(tostring(str).."\n") 
       lg:flush() 
       lg:close()      
end
--------------------------------------------------------------------------------------
function Sortirovka_selection()

sec_list = getClassSecurities(Class_code)

    Tab_sec_list = {}                                   -- Получение всех котируемых фьючерсов на данном классе
    Tabl = {}
    i = 0
    for msec in string.gmatch(sec_list, "[^,]+") do     -- Очищаем данные от лишних знаков
      if msec ~= nil and tostring(msec) ~= '' then
         i = i + 1
        Tab_sec_list[i] = tostring(msec)
      end
    end
  
    i = 0
    for n = 1, #Tab_sec_list do
        param_day = getParamEx(Class_code, Tab_sec_list[n],"DAYS_TO_MAT_DATE")                               -- Получаем количество дней до экспирации
      if (param_day.result == "1") and (param_day.param_image ~= "")  and (param_day.param_type ~= "0") then -- Параметр получен корректно?
            if tonumber(param_day.param_value) > 2 then                                                          -- Считаем только больше 2 дней
                param_vol = tonumber(getParamEx(Class_code, Tab_sec_list[n],"VALTODAY").param_value)             -- Оборот в деньгах    
                Limit_Holding = getFuturesHolding(Firmid, Trdaccid, Tab_sec_list[n], 0)                          -- Проверяем фьючерс на открытые позиции
                if Limit_Holding ~= nil then
                  Open_poz = Open_poz + Limit_Holding.totalnet
                end
                if param_vol  then 

                    i = i + 1
                    Tabl[i] = {}
                    Tabl[i].fut        = tostring(Tab_sec_list[n])          -- Название фьючерса
                    Tabl[i].val        = tostring(math.floor(param_vol))    -- Оборот в деньгах 
                end
            end
        end
    end
   
    -- == Сортируем по обороту в деньгах и оставляем только первые 30 инструментов и записываем их в Таблицу == --
    i = 0
    
    table.sort( Tabl, function ( a,b)  return(tonumber(a.val) > tonumber(b.val)) end )
    for n = 1, 30 do
        Tabl[n].buy_go     = tostring(getParamEx(Class_code, Tabl[n].fut,"BUYDEPO").param_value)        -- ГО покупателя
        Tabl[n].sell_go    = tostring(getParamEx(Class_code, Tabl[n].fut,"SELLDEPO").param_value)       -- ГО продавца
        Tabl[n].step       = tostring(getParamEx(Class_code, Tabl[n].fut,"SEC_PRICE_STEP").param_value) -- Мин. шаг цены
        Tabl[n].step_price = tostring(getParamEx(Class_code, Tabl[n].fut,"STEPPRICE").param_value)      -- Цена шага цены
        Tabl[n].lotsize    = tostring(getParamEx(Class_code, Tabl[n].fut,"LOTSIZE").param_valuee)       -- Размер лота
        Tabl[n].last_price = getParamEx(Class_code, Tabl[n].fut, "LAST").param_value  or  
            getParamEx(Class_code, Tabl[n].fut, "PREVPRICE").param_value                                -- Последняя цена

        TABLE = getBuySellInfo (Firmid, Client_code, Class_code, Tabl[n].fut, tonumber(Tabl[n].last_price)) 
       
        if  math.floor((tonumber(TABLE.can_sell) + tonumber(TABLE.can_buy))/2) >= Risk and 
        Depo /(tonumber(Tabl[n].sell_go) + tonumber(Tabl[n].buy_go))  >= Risk  then

            i = i + 1
            Tabl_sort[i] = Tabl[n] 
            Tabl_sort[i].can_buy_sell = math.floor((tonumber(TABLE.can_sell) + tonumber(TABLE.can_buy))/2)
            --message(Tabl_sort[i].fut.." Фьючерс "..Tabl_sort[i].val.." Оборот в деньгах ".."\n".." Возможно купить или продать контрактов ".. Tabl_sort[i].can_buy_sell ) 
        end
    end  
    Tabl = nil                                              -- Удаляем ненужную таблицу
    
     if  Tabl_sort == nil  then
      message("Вашего депозита не хватает для работы робота, пополните депозит")
     end
    return Tabl_sort
end


function EMA_60()  
     
    Ema = {}
    DS_M60, Error = CreateDataSourse(Class_code, Sec_code, Interval_M60)
    while (Error == nil or Error == "" and DS_M60:Size() == 0) do  sleep(10) end
    if Error ~= nil or Error == nil then 
        message("Ошибка подключения к графику: "..Error) 
    end
    DS_60:SetEmtyCallback()  
    local Highprice_M60 = DS_M60:H(i)
    local Lowprice_M60 = DS_M60:L(i) 
    local Candles_M60 = DS_M60:Size()
    local A_Slow = 2/(Period_Slow+1)
    for i = (Candles_M60 - Ema_Slow), Candles_M60 do
        Highprice_M60 = DS_M60:H(i)
        Lowprice_M60 = DS_M60:L(i) 
        Close_M60 = DS_M60:C(i)   
        SDiapazon_M60 = SDiapazon_M60 + math.abs(tonumber(Highprice_M60)-tonumber(Lowprice_M60) )
        if i >= (Candles_M60 - Period_Slow) then
             
                Ema[i] = Close_60 * A_Slow + Ema[i-1]*(1 - A_Slow)        -- Расчет эспотенциальной скользящей средней
              
        end
        
    end
 
end
-----------------------------------------------------------------------------------
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
    local A_Fast = 2/(Period_Fast+1)
    local A_Slow = 2/(Period_Slow+1)
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
------------------------------------------------------------------------------------------------------------

function main()
    Sortirovka_selection()
    Log("Простой")
    message(tostring(#Tabl_sort))
    for i = 1, #Tabl_sort do
         Log(Tabl_sort[i].fut.." Фьючерс "..Tabl_sort[i].val.." Оборот в деньгах "..Tabl_sort[i].buy_go.." -Го на покупку"..Tabl_sort[i].sell_go.." -Го на продажу"..
         "\n".." Возможно купить или продать контрактов ".. Tabl_sort[i].can_buy_sell ) 
         sleep(200)
    end
end
