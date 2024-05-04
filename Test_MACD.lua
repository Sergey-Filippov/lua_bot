function OnInit()
    Class_code =  "SPBFUT"
    Client_code = "567250R7WF1"                     -- ��� �������
    Firmid = "MC0061900000"  
    Tag = "EQTV"
    Cur_code = "SUR"                                -- ��� ������
    Trdaccid = "76805ks"                            -- �������� ����
    Sec_code = "CNYRUBF"                            -- �������� ����������
    INTERVAL_H4 = 240                              -- ������� ��������
    Period_Slow = 26                                -- ������ ����������� ��������� EMA
    Period_Fast = 12                                 -- ������ ����������� ������� EMA
    SDiapazon_H4 = 0
    log =  getScriptPath().."\\".."Save_one.txt"
end

function Log(str)                               -- ������ ����� ������ 
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
    DS_H4, Error = CreateDataSource(Class_code, Sec_code, INTERVAL_H4)          -- ��������� ������� ������ �� D1
    while (DS_H4:Size() == nil or DS_H4:Size() == 0) do                 -- �������� �������� �� ������
       if Error ~= nil or Error ~="" then 
        message("������ ����������� � �������: "..Error) 
        break end
     
          sleep(100)
        end
    
    message(" ������ ��������")
    DS_H4:SetEmptyCallback()                                                     -- �������� �� �������������� ��������� ����������� ������ (��� D1 ���������?)
    local Delita_price_H4 = 0 
    local Highprice_H4 = 0
    local Lowprice_H4 = 0
    local Data_H4 = {}
    local Candles_H4 = DS_H4:Size()                 -- ���-�� ������ �� ������� �������� ������
    
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
          
            Ema_Slow[i] =  DS_H4:C(i)*A_Slow + Ema_Slow[i-1]*(1 - A_Slow)    -- ������ ��������� EMA
           
            Ema_Fast[i] =  DS_H4:C(i)*A_Fast + Ema_Fast[i-1]*(1 - A_Fast)    --������ ������� EMA
           
            Delita_price_H4 = Delita_price_H4 + math.abs(Highprice_H4 -Lowprice_H4)    -- ������ ����� ���� ������� ����������
       
        if i >= Candles_H4 - Period_Slow then                                               --  ��������� � ������ ��������� 22 ��������
            MACD[i-Period_Slow] = {}
            MACD[i-Period_Slow].macd = tonumber(string.format("%.6f", (Ema_Fast[i] - Ema_Slow[i])))       -- ������ MACD
            MACD[i-Period_Slow].slow = tonumber(string.format("%.6f", Ema_Slow[i] ))
            MACD[i-Period_Slow].fast = tonumber(string.format("%.6f", Ema_Fast[i] ))
            MACD[i-Period_Slow].data = tostring(Data_H4.day..' ����� '..Data_H4.month.." ��� "..Data_H4.hour.." ��� "..Data_H4.min.." ���")
            Str = tostring(MACD[i-Period_Slow].data.." -���� � �����".."\n"..
            MACD[i-Period_Slow].macd.." - MACD  "..MACD[i-Period_Slow].fast.." - fast  "..MACD[i-Period_Slow].slow.." - slow")
           Log(Str)
        end  
        SDiapazon_H4 = Delita_price_H4/Candles_H4                        -- ������ �������������� ���������
    end
   
end

  ------------------------------------------------------
  function OnStop()                           -- ������� ��������� ���� �� ������� ������ "Stop"
    Log("��������� ������� - Stop")
    is_run = false
    
    return 2000   
  end

  function main()
     
    MACD_()
   
  end