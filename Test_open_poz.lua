Trdaccid = "76805ks"
Client_code = "567250R7WF1" 
Firmid = "MC0061900000"
Class_code = "SPBFUT"
Interval_M60 = 60                                 -- 60  Минут
Interval_M15 = 15                                  -- 5 Мин
Interval_D1 = 1440                            -- Дневной интервал
Period_Slow = 26                                -- Период сглаживания медленной EMA
Period_Fast = 12                                 -- Период сглаживания быстрой EMA
SDiapazon = 0   
Sec_code = "VBM4"   
log =  getScriptPath().."\\".."Log_one.txt"        -- Файл записи логов работы 
MACD = {}

function LastPrice(Sec_code)         -- Функция считывает последние котировки с инструмента
  -------------------------------------------------------------------------------------
  
      local Activ_price = getParamEx(Class_code, Sec_code, "LAST").param_value  or  
      getParamEx(Class_code, Sec_code, "PREVPRICE").param_value 
      return Activ_price    
  end

-------------------------------------------------------------------------------------
function Log(str)                               -- Запись логов работы 
-------------------------------------------------------------------------------------
     
     lg = io.open(log, "a+") 
     lg:write(tostring(str).."\n") 
     lg:flush() 
     lg:close()      
end
--[[
Open_poz = 0 -- открытые позиции
sec_list = getClassSecurities(Class_code)

   
    Tab_sec_list = {}
   
    i = 0
    for msec in string.gmatch(sec_list, "[^,]+") do
      if msec ~= nil and tostring(msec) ~= '' then
        if  i == nil then  i=0 end
         i = i + 1
        
        Tab_sec_list[i] = tostring(msec)
                       
      end
    end
 for n = 1, #Tab_sec_list do
  Last_price = getParamEx(Class_code, Tab_sec_list[n], "LAST").param_value  or  
  getParamEx(Class_code, Tab_sec_list[n], "PREVPRICE").param_value   
  --message(tostring(Tab_sec_list[n].."  "..Last_price))
  TABLE = getBuySellInfo (Firmid, Client_code, Class_code, Tab_sec_list[n], tonumber(Last_price))
  if TABLE ~= nil then
        message(Tab_sec_list[n].."\n"..tostring(math.floor((tonumber(TABLE.can_sell) + tonumber(TABLE.can_buy))/2)))
        Limit_Holding = getFuturesHolding(Firmid, Trdaccid, Tab_sec_list[n], 0)
    if Limit_Holding ~= nil then
        Open_poz = Open_poz + Limit_Holding.totalnet
    end
  end
end  
message ("Открыто "..Open_poz.." Позиций")
]]--

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
  local A_Fast = 2/(Period_Fast+1)
  local A_Slow = 2/(Period_Slow+1)
  for i = 2, Candles do
      Highprice = DS:H(i)                   -- High
      Lowprice = DS:L(i)                    -- Low
      Data = DS:T(i)
          Ema_Slow[i] = DS:C(i)
          Ema_Fast[i] = DS:C(i)
        
          Ema_Slow[i] =  DS:C(i)*A_Slow + Ema_Slow[i-1]*(1 - A_Slow)    -- Расчет медленной EMA
          Ema_Fast[i] =  DS:C(i)*A_Fast + Ema_Fast[i-1]*(1 - A_Fast)    --Расчет быстрой EMA
          Delita_price = Delita_price + math.abs(Highprice -Lowprice)    -- Расчет суммы всех дневных диапазонов
          Index = (i + Period_Fast) - Candles
      if Index >=1 then                                               --  Оставляем в памяти последние 22 значения
          MACD[Index] = {}
          MACD[Index].macd = tonumber(string.format("%.6f", (Ema_Fast[i] - Ema_Slow[i])))       -- Расчет MACD
          MACD[Index].slow = tonumber(string.format("%.6f", Ema_Slow[i] ))
          MACD[Index].fast = tonumber(string.format("%.6f", Ema_Fast[i] ))
          MACD[Index].data = tostring(Data.day..' число '..Data.month.." мес ")
      end  
  
  end
  SDiapazon = Delita_price/(Candles-1)                       -- Расчет среднедневного диапазона
  local S = tostring(LastPrice(Sec_code)*10/10)
  local len = #S
  
  --SDiapazon = math.floor(SDiapazon * 10^len)
  message(tostring(S.."  "..len))
  message(tostring(string.find(S, "%D" )))
  return MACD, SDiapazon
end

function OnStop()
  return 1000
end
-----------------------------
function main()
   MACD_(Sec_code, Interval_D1) 
  
  for i = 1, #MACD do
      Str = tostring(MACD[i].data.." -дата и время".."\n"..
      MACD[i].macd.." - MACD  "..MACD[i].fast.." - fast  "..MACD[i].slow.." - slow")
     Log(Str)
  end
  Log(SDiapazon)
end