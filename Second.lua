----  Простой робот по индикаторам тех анализа  ----
------------------------------------------------------------------
function OnInit()  -- Первичная инициализация данных
------------------------------------------------------------------    
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
    Interval_D1 = 1440                            -- Дневной интервал
    Period_Slow = 26                                -- Период сглаживания медленной EMA
    Period_Fast = 12                                 -- Период сглаживания быстрой EMA
    SDiapazon_H4 = 0                 
    Risk = 2
    Open_poz = 0                                        -- открытые позиции 
    log =  getScriptPath().."\\".."Save_one.txt"        -- Файл записи логов работы
    Tabl_sort = {}                                      -- Отсортированная таблица данных
    MACD = {}
end
----------------------------------------------------------------------------------------------------
function Status() --Функция проверки состояния подключения 
----------------------------------------------------------------------------------------------------    
    local connect = tostring(math.ceil( isConnected() ))
    local status = tostring(math.ceil(getParamEx(Class_code, Sec_code, "STAtUS").param_value) or 0)
    local session_status = tostring(math.ceil(getFuturesHolding(Firmid,Trdaccid,Sec_code, 0).session_status) or 0)
     
end
------------------------------------------------------------------------------------------------------------
--[[ функция раскраски ячеек/строк где функция Color(color, id, row, column) возвращает
color - название цвета (например : "Голубой") id - имя таблицы
row и column - строка и столбец указывающие на конкретную ячейку таблицы, которую раскрашиваем
]]--
function Color(color, id, row, column)  

    if not column then column = QTABLE_NO_INDEX end        -- Если индекс столбца не указан окрашивает всю строку
   
    if color ==  "Красный шрифт" then SetColor (id, row, column, RGB(255, 255, 255), RGB(255, 000, 000), RGB(255, 255, 255), RGB(255, 000, 000))  end
    if color ==  "Синий шрифт"   then SetColor (id, row, column, RGB(255, 255, 255), RGB(000, 000, 255), RGB(255, 255, 255), RGB(000, 000, 255))  end
    if color ==  "Лайм шрифт"    then SetColor (id, row, column, RGB(255, 255, 255), RGB(000, 255, 000), RGB(255, 255, 255), RGB(000, 255, 000))  end
    if color ==  "Голубой"       then SetColor (id, row, column, RGB(173, 216, 230), RGB(000, 000, 000), RGB(173, 216, 230), RGB(000, 000, 000))  end  
    if color ==  "Жёлтый"        then SetColor (id, row, column, RGB(255, 255, 000), RGB(000, 000, 000), RGB(255, 255, 000), RGB(000, 000, 000))  end
    if color ==  "Серый"         then SetColor (id, row, column, RGB(128, 128, 128), RGB(000, 000, 000), RGB(128, 128, 128), RGB(000, 000, 000))  end
    if color ==  "Темносерый"    then SetColor (id, row, column, RGB(050, 080, 080), RGB(000, 000, 000), RGB(050, 080, 080), RGB(000, 000, 000))  end
    if color ==  "Синий"         then SetColor (id, row, column, RGB(000, 000, 255), RGB(000, 000, 000), RGB(000, 000, 255), RGB(000, 000, 000))  end
    if color ==  "Оранжевый"     then SetColor (id, row, column, RGB(255, 165, 000), RGB(000, 000, 000), RGB(255, 165, 000), RGB(000, 000, 000))  end
    if color ==  "Лайм"          then SetColor (id, row, column, RGB(000, 255, 000), RGB(000, 000, 000), RGB(000, 255, 000), RGB(000, 000, 000))  end
    if color ==  "Красный"       then SetColor (id, row, column, RGB(255, 000, 000), RGB(000, 000, 000), RGB(255, 000, 000), RGB(000, 000, 000))  end
    if color ==  "Фуксия"        then SetColor (id, row, column, RGB(255, 000, 255), RGB(000, 000, 000), RGB(255, 000, 255), RGB(000, 000, 000))  end
    if color ==  "Кровь"         then SetColor (id, row, column, RGB(130, 000, 000), RGB(000, 000, 000), RGB(130, 000, 000), RGB(000, 000, 000))  end
    if color ==  "Аква"          then SetColor (id, row, column, RGB(000, 255, 255), RGB(000, 000, 000), RGB(000, 255, 255), RGB(000, 000, 000))  end
    if color ==  "Зеленый"       then SetColor (id, row, column, RGB(034, 140, 034), RGB(000, 000, 000), RGB(034, 140, 034), RGB(000, 000, 000))  end
end
-------------------------------------------------------------------------------------------------------------
function LastPrice(Sec_code)         -- Функция считывает последние котировки с инструмента
    -------------------------------------------------------------------------------------
    
        local Activ_price = getParamEx(Class_code, Sec_code, "LAST").param_value  or  
        getParamEx(Class_code, Sec_code, "PREVPRICE").param_value 
        return Activ_price                                          -- Возвращает или последнюю котировку на сегодня или последнюю котировку предыдущего дня
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
function Sortirovka_selection() -- Функция получает данные по фьючерсам и сортирует их на основе дипозита и оборота в деньгах
--------------------------------------------------------------------------------------
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
            if tonumber(param_day.param_value) > 5 then                                                          -- Считаем только больше 5 дней
                param_vol = tonumber(getParamEx(Class_code, Tab_sec_list[n],"VALTODAY").param_value)             -- Оборот в деньгах    
                Limit_Holding = getFuturesHolding(Firmid, Trdaccid, Tab_sec_list[n], 0)                          -- Проверяем фьючерс на открытые позиции
                if Limit_Holding ~= nil then
                  Open_poz = Open_poz + Limit_Holding.totalnet                                                   -- Считаем количество открытых позиций по фьючерсам
                end
                if param_vol  then                                          -- если оборот в деньгах получен то записываем в таблицу:

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
    
    table.sort( Tabl, function ( a,b)  return(tonumber(a.val) > tonumber(b.val)) end )      -- Функция сортировки по обороту
    for n = 1, 50 do                                                                        -- оставляем первые 50 фьючерсов и получаем по ним остальные данные
        Tabl[n].buy_go     = tostring(getParamEx(Class_code, Tabl[n].fut,"BUYDEPO").param_value)        -- ГО покупателя
        Tabl[n].sell_go    = tostring(getParamEx(Class_code, Tabl[n].fut,"SELLDEPO").param_value)       -- ГО продавца
        Tabl[n].step       = tostring(getParamEx(Class_code, Tabl[n].fut,"SEC_PRICE_STEP").param_value) -- Мин. шаг цены
        Tabl[n].step_price = tostring(getParamEx(Class_code, Tabl[n].fut,"STEPPRICE").param_value)      -- Цена шага цены
        Tabl[n].lotsize    = tostring(getParamEx(Class_code, Tabl[n].fut,"LOTSIZE").param_valuee)       -- Размер лота
        Tabl[n].last_price = LastPrice(Tabl[n].fut)                                -- Последняя цена

        TABLE = getBuySellInfo (Firmid, Client_code, Class_code, Tabl[n].fut, tonumber(Tabl[n].last_price)) 
       
        if  math.floor((tonumber(TABLE.can_sell) + tonumber(TABLE.can_buy))/2) >= 1  and        -- Если мы можем продать или купить больше 1 контракта
        Depo /(tonumber(Tabl[n].sell_go) + tonumber(Tabl[n].buy_go))  >= 1  then                -- И нашего депо хватит для двойного обеспечения то:

            i = i + 1
            Tabl_sort[i] = Tabl[n]                                                              -- Мы данные записываем в новую таблицу
            Tabl_sort[i].can_buy_sell = math.floor((tonumber(TABLE.can_sell) + tonumber(TABLE.can_buy))/2)  -- Добавляя количество доступных для покупки или
        end                                                                                                 -- продажи контрактов
    end  
    Tabl = nil                                              -- Удаляем ненужную таблицу
    
     if  Tabl_sort == nil  then                             -- Если в таблицу ничего не записалось - значет мало денег на депо
      message("Вашего депозита не хватает для работы робота, пополните депозит")
     end
    return Tabl_sort
end

-----------------------------------------------------------------------------------
function MACD_(Sec_code, Interval)
   
    Ema_Fast = {}
    Ema_Slow = {}
    DS, Error = CreateDataSource(Class_code, Sec_code, Interval)          -- Получение таблицы данных по D1
    while (DS:Size() == nil or DS:Size() == 0) do                 -- Проверка получены ли данные
       if Error ~= nil or Error ~="" then 
        message("Ошибка подключения к графику: "..Error) 
        break end
     
          sleep(100)
        end
    
    if DS ~= nil then message(" Данные получены") end
    DS:SetEmptyCallback()                                                     -- Подписка на автоматическое получение обновленных данных (Для D1 актуально?)
    local Delita_price = 0 
    local Highprice = 0
    local Lowprice = 0
    local Data = {}
    local Candles = DS:Size()                 -- Кол-во свечей по которым получены данные
    
    Ema_Slow[1] = DS:C(1) 
    Ema_Fast[1] = DS:C(1)
    local A_Fast = 2/(Period_Fast+1)        -- коэф сглаживания для быстрой скользящей
    local A_Slow = 2/(Period_Slow+1)        -- коэф сглаживания для медленной скользящей
    for i = 2, Candles do
        Highprice = DS:H(i)                   -- High
        Lowprice = DS:L(i)                    -- Low
        Data = DS:T(i)                        -- дата и время
            Ema_Slow[i] = DS:C(i)
            Ema_Fast[i] = DS:C(i)
          
            Ema_Slow[i] =  DS:C(i)*A_Slow + Ema_Slow[i-1]*(1 - A_Slow)    -- Расчет медленной EMA
            Ema_Fast[i] =  DS:C(i)*A_Fast + Ema_Fast[i-1]*(1 - A_Fast)    --Расчет быстрой EMA
            Delita_price = Delita_price + math.abs(Highprice -Lowprice)    -- Расчет суммы всех дневных диапазонов
            Index = (i + Period_Fast) - Candles
        if Index >=1 then                                               --  Оставляем в памяти последние 22 значения
            MACD[Index] = {}
            MACD[Index].macd = tonumber(string.format("%.6f", (Ema_Fast[i] - Ema_Slow[i])))       -- Расчет MACD
            MACD[Index].slow = tonumber(string.format("%.6f", Ema_Slow[i] ))                      -- Сохраняем значение медленной скользящей
            MACD[Index].fast = tonumber(string.format("%.6f", Ema_Fast[i] ))                      -- Сохраняем значение быстрой скользящей
            if Interval == Interval_D1 then
                MACD[Index].day = tostring(Data.day..' число ')                                   -- Сохраняем число и месяц для Interval= день
                MACD[Index].month =tostring(Data.month.." мес ")
            else
                MACD[Index].day = tostring(Data.day..' число ')
                MACD[Index].hour = tostring(Data.hour.." час ")                                    -- Сохраняем число, час и мин для другого интервала
                MACD[Index].min = tostring(Data.min.." мин")
            end
        end  
    
    end
    SDiapazon = Delita_price/(Candles-1)                       -- Расчет среднедневного диапазона
    local S = tostring(LastPrice(Sec_code)*10/10)               -- Узнаём последнюю цену инструмента и удаляем лишние нули
    local len = #S                                              -- Длинна полученной строки
    local poz = string.find(S, "%D" )                           -- находим позицию точки или запятой
    if tonumber(string.sub(S, poz+1, len)) ~= 0 then            -- Если после запятой не одни нули, то
    len = #string.sub(S, poz+1, len)                            -- получаем подстроку от запятой до последнего знака
    SDiapazon = (SDiapazon*10^len) + 0.5                        -- получаем средний диапазон в пунктах с округлением
    end
    SDiapazon = math.floor( SDiapazon)                          -- если после запятой одни нули, просто отбрасываем их
    return MACD, SDiapazon
end
-----------------------------------------------------------------------------------------------------------
function First_Table ()      -- Функция создает таблицу
    t_id = AllocTable ()     -- Получает доступный id для создания
----------------------------------------------------------------------------------------
    AddColumn (t_id, 1, "Тикер", true, QTABLE_INT_TYPE, 12)
    AddColumn (t_id, 2, "Кол-во доступных контрактов",   true, QTABLE_INT_TYPE, 37)
    AddColumn (t_id, 3, "Оборот в деньгах",  true, QTABLE_INT_TYPE, 22)
    AddColumn (t_id, 4, "Мин. шаг цены",  true, QTABLE_INT_TYPE, 20)
    AddColumn (t_id, 5, "Цена шага",  true, QTABLE_INT_TYPE, 17)

    CreateWindow (t_id)                                 -- Создаёт таблицу
    SetWindowCaption (t_id, "ВЫБЕРЕТЕ ФЬЮЧЕРС ДЛЯ РАБОТЫ РОБОТА")       -- Устанавливает заголовок
    SetWindowPos (t_id, 0, 0, 593, 120)                 -- Задает положение и размер окна 0,0 - начало x,y - конец окна 
----------------------------------------------------------------------------------------
    
    for m = 1, #Tabl_sort do
        InsertRow(t_id, -1)
    if math.fmod( m,2 ) == 0 then
        Color ("Голубой", t_id, m, 1)
        Color ("Голубой", t_id, m, 2)
        Color ("Голубой", t_id, m, 3)
        Color ("Голубой", t_id, m, 4)
        Color ("Голубой", t_id, m, 5) 
        else 
        Color ("Аква", t_id, m, 1)
        Color ("Аква", t_id, m, 2)
        Color ("Аква", t_id, m, 3)
        Color ("Аква", t_id, m, 4)
        Color ("Аква", t_id, m, 5)  
        end
    
    SetCell (t_id, m, 1, tostring(Tabl_sort[m].fut));             
    SetCell (t_id, m, 2, tostring(Tabl_sort[m].can_buy_sell));    
    SetCell (t_id, m, 3, tostring(Tabl_sort[m].val));             
    SetCell (t_id, m, 4, tostring(Tabl_sort[m].step));            
    SetCell (t_id, m, 5, tostring(Tabl_sort[m].step_price));      
    
    end 

    --SetTableNotificationCallback (t_id, Table_Callback)               -- Функция реагирует на мышь

end   
------------------------------------------------------------------------------------------------------------
function OnStop()                    -- Функция остановки бота по нажатию кнопки "Stop"
    Log("Остановка скрипта OnStop")
    DestroyTable(t_id)
    is_run = false
    return 1000
end
-------------------------------------------------------------------------------------------------------------

function main()
    Sortirovka_selection()
   
    for i = 1, #Tabl_sort do

         Log(Tabl_sort[i].fut.." Фьючерс "..Tabl_sort[i].val.." Оборот в деньгах "..Tabl_sort[i].buy_go.." -Го на покупку"..Tabl_sort[i].sell_go.." -Го на продажу"..
         "\n".." Возможно купить или продать контрактов ".. Tabl_sort[i].can_buy_sell ) 
    end
    
   if Tabl_sort ~= nil then MACD_(Tabl_sort[1].fut, Interval_D1) end
   First_Table ()
    for i = 1, #MACD do
        Str = tostring(MACD[i].day.." "..MACD[i].month.." -дата и время".."\n"..
       MACD[i].macd.." - MACD  "..MACD[i].fast.." - fast  "..MACD[i].slow.." - slow")
       Log(Str)
    end
    Log(SDiapazon)
end
