----  ������� ����� �� ����������� ��� �������  ----
-----------------------------------------------
function OnInit()  -- ��������� ������������� ������
    Name_Bot = "��� �� ���������� �������"          -- ������������ ������
    Version = " 1.0"                                -- ����� ������ ����
    Sec_code = "CNYRUBF"                                   -- ������������ ��������� �����������
    Class_code =  "SPBFUT"
    Client_code = "567250R7WF1"                     -- ��� �������
    Firmid = "MC0061900000"  
    Tag = "EQTV"
    Cur_code = "SUR"                                -- ��� ������
    Trdaccid = "76805ks"                            -- �������� ����
    Status, Connect, Session_status = 0, 0, 0       -- ��������� �������������
    Stop = "off"                                    -- ����� ������ ������ �����/������
    Depo = getMoney(Client_code, Firmid, Tag, Cur_code).money_limit_available  -- �������
    Interval_M60 = 60                                 -- 60  �����
    Interval_M15 = 15                                 -- 5 ���
    Interval_D1 = 1440                                -- ������� ��������
    Period_Slow = 26                                  -- ������ ����������� ��������� EMA
    Period_Fast = 12                                  -- ������ ����������� ������� EMA
    SDiapazon = 0                 
    Risk = 2
    Open_poz = 0                                        -- �������� ������� 
    log =  getScriptPath().."\\".."Save_one.txt"        -- ���� ������ ����� ������
    Tabl_sort = {}                                      -- ��������������� ������� ������
end

function Status() --������� �������� ��������� ����������� 
    local connect = tostring(math.ceil( isConnected() ))
    local status = tostring(math.ceil(getParamEx(Class_code, Sec_code, "STAtUS").param_value) or 0)
    local session_status = tostring(math.ceil(getFuturesHolding(Firmid,Trdaccid,Sec_code, 0).session_status) or 0)
     
end




-------------------------------------------------------------------------------------
function Log(str)                               -- ������ ����� ������ 
-------------------------------------------------------------------------------------
       
       lg = io.open(log, "a+") 
       lg:write(tostring(str).."\n") 
       lg:flush() 
       lg:close()      
end

--------------------------------------------------------------------------------------
function Sortirovka_selection()

sec_list = getClassSecurities(Class_code)

    Tab_sec_list = {}                                   -- ��������� ���� ���������� ��������� �� ������ ������
    Tabl = {}
    i = 0
    for msec in string.gmatch(sec_list, "[^,]+") do     -- ������� ������ �� ������ ������
      if msec ~= nil and tostring(msec) ~= '' then
         i = i + 1
        Tab_sec_list[i] = tostring(msec)
      end
    end
  
    i = 0
    for n = 1, #Tab_sec_list do
        param_day = getParamEx(Class_code, Tab_sec_list[n],"DAYS_TO_MAT_DATE")                               -- �������� ���������� ���� �� ����������
      if (param_day.result == "1") and (param_day.param_image ~= "")  and (param_day.param_type ~= "0") then -- �������� ������� ���������?
            if tonumber(param_day.param_value) > 2 then                                                          -- ������� ������ ������ 2 ����
                param_vol = tonumber(getParamEx(Class_code, Tab_sec_list[n],"VALTODAY").param_value)             -- ������ � �������    
                Limit_Holding = getFuturesHolding(Firmid, Trdaccid, Tab_sec_list[n], 0)                          -- ��������� ������� �� �������� �������
                if Limit_Holding ~= nil then
                  Open_poz = Open_poz + Limit_Holding.totalnet
                end
                if param_vol  then 

                    i = i + 1
                    Tabl[i] = {}
                    Tabl[i].fut        = tostring(Tab_sec_list[n])          -- �������� ��������
                    Tabl[i].val        = tostring(math.floor(param_vol))    -- ������ � ������� 
                end
            end
        end
    end
   
    -- == ��������� �� ������� � ������� � ��������� ������ ������ 30 ������������ � ���������� �� � ������� == --
    i = 0
    
    table.sort( Tabl, function ( a,b)  return(tonumber(a.val) > tonumber(b.val)) end )
    for n = 1, 30 do
        Tabl[n].buy_go     = tostring(getParamEx(Class_code, Tabl[n].fut,"BUYDEPO").param_value)        -- �� ����������
        Tabl[n].sell_go    = tostring(getParamEx(Class_code, Tabl[n].fut,"SELLDEPO").param_value)       -- �� ��������
        Tabl[n].step       = tostring(getParamEx(Class_code, Tabl[n].fut,"SEC_PRICE_STEP").param_value) -- ���. ��� ����
        Tabl[n].step_price = tostring(getParamEx(Class_code, Tabl[n].fut,"STEPPRICE").param_value)      -- ���� ���� ����
        Tabl[n].lotsize    = tostring(getParamEx(Class_code, Tabl[n].fut,"LOTSIZE").param_valuee)       -- ������ ����
        Tabl[n].last_price = getParamEx(Class_code, Tabl[n].fut, "LAST").param_value  or  
            getParamEx(Class_code, Tabl[n].fut, "PREVPRICE").param_value                                -- ��������� ����

        TABLE = getBuySellInfo (Firmid, Client_code, Class_code, Tabl[n].fut, tonumber(Tabl[n].last_price)) 
       
        if  math.floor((tonumber(TABLE.can_sell) + tonumber(TABLE.can_buy))/2) >= Risk and 
        Depo /(tonumber(Tabl[n].sell_go) + tonumber(Tabl[n].buy_go))  >= Risk  then

            i = i + 1
            Tabl_sort[i] = Tabl[n] 
            Tabl_sort[i].can_buy_sell = math.floor((tonumber(TABLE.can_sell) + tonumber(TABLE.can_buy))/2)
            --message(Tabl_sort[i].fut.." ������� "..Tabl_sort[i].val.." ������ � ������� ".."\n".." �������� ������ ��� ������� ���������� ".. Tabl_sort[i].can_buy_sell ) 
        end
    end  
    Tabl = nil                                              -- ������� �������� �������
    
     if  Tabl_sort == nil  then
      message("������ �������� �� ������� ��� ������ ������, ��������� �������")
     end
    return Tabl_sort
end

-----------------------------------------------------------------------------------
function MACD_(Interval)
    Ema_Fast = {}
    Ema_Slow = {}
    MACD = {}
    DS, Error = CreateDataSource(Class_code, Sec_code, Interval)          -- ��������� ������� ������ �� D1
    while (DS:Size() == nil or DS:Size() == 0) do                         -- �������� �������� �� ������
       if Error ~= nil or Error ~="" then 
        message("������ ����������� � �������: "..Error)      
    end
          sleep(100)
        end
    
    message(" ������ ��������")
    DS:SetEmptyCallback()                                                     -- �������� �� �������������� ��������� ����������� ������ (��� D1 ���������?)
    local Delita_Price = 0 
    local High_price = 0
    local Low_price = 0
    local Data = {}
    local Candless = DS:Size()                 -- ���-�� ������ �� ������� �������� ������
    
    Ema_Slow[1] = DS:C(1) 
    Ema_Fast[1] = DS:C(1)
    local A_Fast = 2/(Period_Fast+1)
    local A_Slow = 2/(Period_Slow+1)
    for i = 2, Candless do
        High_price = DS:H(i)                   -- High
        Low_price = DS:L(i)                    -- Low
        Data = DS:T(i)
            Ema_Slow[i] = DS:C(i)
            Ema_Fast[i] = DS:C(i)
          
            Ema_Slow[i] =  DS:C(i)*A_Slow + Ema_Slow[i-1]*(1 - A_Slow)    -- ������ ��������� EMA
           
            Ema_Fast[i] =  DS:C(i)*A_Fast + Ema_Fast[i-1]*(1 - A_Fast)    --������ ������� EMA
           
            Delita_Price = Delita_Price + math.abs(High_price -Low_price)    -- ������ ����� ���� ������� ����������
       
        if i >= Candless - Period_Slow then                                               --  ��������� � ������ ��������� 22 ��������
            MACD[i-Period_Slow] = {}
            MACD[i-Period_Slow].macd = tonumber(string.format("%.6f", (Ema_Fast[i] - Ema_Slow[i])))       -- ������ MACD
            MACD[i-Period_Slow].slow = tonumber(string.format("%.6f", Ema_Slow[i] ))
            MACD[i-Period_Slow].fast = tonumber(string.format("%.6f", Ema_Fast[i] ))
            MACD[i-Period_Slow].data =  Data
           
        end  
        SDiapazon = Delita_Price/Candless                        -- ������ �������������� ���������
        return MACD, SDiapazon
    end
   
end

------------------------------------------------------------------------------------------------------------
function OnStop()                           -- ������� ��������� ���� �� ������� ������ "Stop"
    Log("��������� ������� - Stop")
    is_run = false
    
    return 1000   
end
--------------------------------------------------------------------------------------------------------------

function main()
    Sortirovka_selection()
    Log("�������")
    message(tostring(#Tabl_sort))
    for i = 1, #Tabl_sort do
         Log(Tabl_sort[i].fut.." ������� "..Tabl_sort[i].val.." ������ � ������� "..Tabl_sort[i].buy_go.." -�� �� �������"..Tabl_sort[i].sell_go.." -�� �� �������"..
         "\n".." �������� ������ ��� ������� ���������� ".. Tabl_sort[i].can_buy_sell ) 
         sleep(200)
    end
    MACD_(Interval_D1)
    message(tostring(#MACD))
    for i = 1, #MACD do
        Str = tostring(MACD[i].data.day.." -���� � �����".."\n"..
        MACD[i].macd.." - MACD  "..MACD[i].fast.." - fast  "..MACD[i].slow.." - slow")
       Log(Str)
    end
    Log(SDiapazon)
end
