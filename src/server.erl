%%%-------------------------------------------------------------------
%%% @author prokopiy
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. Дек. 2014 12:26
%%%-------------------------------------------------------------------
-module(server).
-author("prokopiy").
-vsn(["0.0.1"]).

%% API
-export([start/0, loop/1]).

%%
start() ->

  {compile, C} = lists:keyfind(compile, 1, module_info()),
  {version, V} = lists:keyfind(version, 1, C),
  {time, T} = lists:keyfind(time, 1, C),
  io:format("version = ~w, time = ~w~n", [V, T]),
  io:format("Neuronet server started at ~w on ~w~n", [self(), node()]),
  {A1, A2, A3} = now(),
  random:seed(A1, A2, A3),

%%   {_Date, Time} = calendar:local_time(),
%%   random:seed(Time),

  Data = #{
    owner => self(),
    clients => #{}

  },
  register(mbox, spawn(server, loop, [Data])),
  receive
    A ->
      io:format("~w~n", [A])
  end.

%%   spawn(server, loop, [Data]).
%%   loop(Data).


loop(Data) ->
  receive
    {allocate, Pid, {Layers, MemorySize}} ->
      N = net:new(Layers, MemorySize),
      CurrentClients = maps:get(clients, Data),
      NewClients = maps:put(Pid, N, CurrentClients),
      NewData = Data#{clients := NewClients},
      io:format("Allocated ~w~n", [NewData]),
      loop(NewData);
    {pulse, Pid, Value} when is_list(Value) ->
      CurrentClients = maps:get(clients, Data),
      io:format("CurrentClients = ~w~n", [CurrentClients]),
      Net = maps:get(Pid, CurrentClients),
      io:format("Net = ~w~n", [Net]),
      R = net:pulse(Net, Value),
      io:format("R = ~w~n", [R]),
      Pid ! {reply, self(), R},
      loop(Data);
    {correct, Pid, Value} when is_list(Value) ->
      CurrentClients = maps:get(clients, Data),
      io:format("correct: CurrentClients = ~w~n", [CurrentClients]),
      Net = maps:get(Pid, CurrentClients),
      io:format("Net = ~w~n", [Net]),
      R = net:true_output(Net, Value),
      io:format("R = ~w~n", [R]),
      Pid ! {reply, self(), R},
      loop(Data);
    A ->
      io:format("main:loop(): ~w ~n", [A]),
      loop(Data)
  after
    50000 ->
      io:format("Neuronet server stopped~n"),
      maps:get(owner, Data) ! true
  end.



reply(Pid, Reply) ->
  Pid ! {reply, Reply}.