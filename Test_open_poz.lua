Trdaccid = "76805ks"
Client_code = "567250R7WF1" 
Firmid = "MC0061900000"
Class_code = "SPBFUT"
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