//+------------------------------------------------------------------+
//|                                                          EMA.mq4 |
//|                                                          arc6828 |
//|                                     https://medium.com/ckartisan |
//+------------------------------------------------------------------+
#property copyright "arc6828"
#property link      "https://medium.com/ckartisan"
#property description "Exponential Moving Average expert advisor"
#property version   "1.00"
#property strict

#define MAGICMA  20230418
//--- Inputs
input double Lots          =0.1;
input double MaximumRisk   =0.02;
input double DecreaseFactor=3;
input int    MovingPeriod  =8;
input int    MovingPeriod2  =15;
input int    MovingPeriod3  =24;
input int    MovingPeriodConfirm  =200;
input int    MovingShift   =6;
input double    RiskRewardRatio   =1.5;
//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
int CalculateCurrentOrders(string symbol)
  {
   int buys=0,sells=0;
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
        }
     }
//--- return orders volume
   if(buys>0) return(buys);
   else       return(-sells);
  }
//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double LotsOptimized()
  {
   double lot=Lots;
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
//--- select lot size
   lot=NormalizeDouble(AccountBalance()/MaximumRisk/1000000.0,2);
//--- calcuulate number of losses orders without a break
   // if(DecreaseFactor>0)
   //   {
   //    for(int i=orders-1;i>=0;i--)
   //      {
   //       if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
   //         {
   //          Print("Error in history!");
   //          break;
   //         }
   //       if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL)
   //          continue;
   //       //---
   //       if(OrderProfit()>0) break;
   //       if(OrderProfit()<0) losses++;
   //      }
   //    if(losses>1)
   //       lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
   //   }
//--- return lot size
   if(lot<0.01) lot=0.01;
   return(lot);
  }
//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForOpen()
  {
   double ma,ma2,ma3,maConfirmed,range;
   int    res;
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get Moving Average    
   ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_EMA,PRICE_CLOSE,0);   
   ma2=iMA(NULL,0,MovingPeriod2,MovingShift,MODE_EMA,PRICE_CLOSE,0);
   ma3=iMA(NULL,0,MovingPeriod3,MovingShift,MODE_EMA,PRICE_CLOSE,0);
   maConfirmed=iMA(NULL,0,MovingPeriodConfirm,MovingShift,MODE_EMA,PRICE_CLOSE,0);
   

   range = MathAbs(Close[1]-ma3);
//--- sell conditions
   if(Open[1]>ma && Close[1]<ma && ma < ma2 && ma2 < maConfirmed)
     {
      res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,Close[1]+range,Close[1]-range*RiskRewardRatio,"",MAGICMA,0,Red);
      return;
     }
//--- buy conditions
   if(Open[1]<ma && Close[1]>ma &&  ma > ma2 && ma2 > maConfirmed)
     {
      res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,Close[1]-range,Close[1]+range*RiskRewardRatio,"",MAGICMA,0,Blue);
      return;
     }
//---
  }
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose()
  {
   double ma;
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get Moving Average 
   ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      //--- check order type 
      if(OrderType()==OP_BUY)
        {
         if(Open[1]>ma && Close[1]<ma)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               Print("OrderClose error ",GetLastError());
           }
         break;
        }
      if(OrderType()==OP_SELL)
        {
         if(Open[1]<ma && Close[1]>ma)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
               Print("OrderClose error ",GetLastError());
           }
         break;
        }
     }
//---
  }
//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- check for history and trading
   if(Bars<100 || IsTradeAllowed()==false)
      return;
//--- calculate open orders by current symbol
   if(CalculateCurrentOrders(Symbol())==0) CheckForOpen();
   // else                                    CheckForClose();
//---
  }
//+------------------------------------------------------------------+
