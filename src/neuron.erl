%%%-------------------------------------------------------------------
%%% @author prokopiy
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%% Модуль реализует работу нейрона в нейросети дискретного времени
%%% Нейрон имеет память(задержку)
%%% Нейрон посылает сигнал на выход сразу после того как получит сигнал со всех входов
%%% Сигнал с выходных нейронов посылается инициатору текущей волны в виде кортежа {reply, Pid_выходного нейрона, {effect, Power}}
%%% @end
%%% Created : 13. Дек. 2014 21:57
%%%-------------------------------------------------------------------

-module(neuron).
-author("prokopiy").

%% API jjjj
-export([new/0, new/1, register_link/3]).
% -export([new/1, loop/1, call/2, print_message/0, stop_message/0, set_link_out_message/2, set_link_in_message/2, register_link/3, new/0]).


new() ->
  new(0).

new(Memory_size) ->
  Data = #{
           in_powers => [],
           memory => gen_clean_memory(Memory_size),
           in_links => #{},
           out_links => #{},
           error => 0,
           num_active_links => 0
          },
  spawn(neuron, loop, [Data]).


call(Pid, Message) ->
  Pid ! {request, self(), Message},
  receive
    {reply, Pid, Reply} -> Reply
%%     {reply, OtherPid, Reply} ->
%%       io:format("Other ~w reply = ~w~n", [OtherPid, Reply])
  end.


% print_message() ->
%   print.

% stop_message() ->
%   stop.

% set_link_out_message(Output_neuron_Pid, Link_weight) ->
%   {set_link_out, Output_neuron_Pid, Link_weight}.

% set_link_in_message(Input_neuron_Pid, Link_weight) ->
%   {set_link_in, Input_neuron_Pid, Link_weight}.

print(Neuron_pid) ->
  call(Neuron_pid, print).
  


loop(Data) ->
  receive
    {reply, _, ok} ->
      loop(Data);
    {request, Pid, print} ->
      io:format("Neuron~w ~w~n", [self(), Data]),
      Pid ! {reply, self(), ok},
      loop(Data);
    {request, Pid, stop} ->
      io:format("Neuron~w stopped~n", [self()]),
      Pid ! {reply, self(), ok};
    {request, Pid, {set_link_out, Output_neuron_pid, W}} ->
      Current_out_links = maps:get(out_links, Data),
      New_out_links = maps:put(Output_neuron_pid, W, Current_out_links),
      NewData = Data#{out_links := New_out_links},
      Pid ! {reply, self(), ok},
      loop(NewData);
    {request, Pid, {set_link_in, Input_neuron_pid, W}} ->
      Current_in_links = maps:get(in_links, Data),
      New_in_links = maps:put(Input_neuron_pid, W, Current_in_links),
      NewData = Data#{in_links := New_in_links},
      Pid ! {reply, self(), ok},
      loop(NewData);
    {request, Pid, {pulse, From, Power}} ->
      {in_powers, Current_in_powers} = lists:keyfind(in_powers, 1, Data),
      New_in_powers = lists:keystore(Pid, 1, Current_in_powers, {Pid, Power}),
      New_in_powers_length = length(New_in_powers),
      {in_links, Current_in_links} = lists:keyfind(in_links, 1, Data),
      Current_in_links_length = length(Current_in_links),
%%       io:format("~w: Current_in_links_length=~w~n", [self(), Current_in_links_length]),
%%       io:format("~w: New_in_powers_length=~w~n", [self(), New_in_powers_length]),

      if
        New_in_powers_length < Current_in_links_length ->
          NewData = lists:keyreplace(in_powers, 1, Data, {in_powers, New_in_powers}),
          Pid ! {reply, self(), ok},
          loop(NewData);
        New_in_powers_length >= Current_in_links_length ->
          Sum_in_powers = lists:foldl(fun({_, Poweri}, Acc) -> Acc + Poweri end, 0, New_in_powers),
%%           io:format("~w: Sum_in_powers=~w~n", [self(), Sum_in_powers]),

          {memory, Current_memory} = lists:keyfind(memory, 1, Data),
%%           io:format("~w: Current_memory=~w~n", [self(), Current_memory]),
%%           {memory, Current_F} = lists:keyfind(func, 1, Data),
          New_memory1 = Current_memory ++ [math:tanh(Sum_in_powers)],
          [Last_power | New_memory] = New_memory1,


          {out_links, Out} = lists:keyfind(out_links, 1, Data),
          if
            Out == [] ->
              io:format("Neuron~w: send effect ~w to ~w~n", [self(), Last_power, From]),
              From ! {reply, self(), {effect, Last_power}};
            Out /= [] ->
              true
          end,
          calc_and_pulse_all(self(), {From, Last_power}, Out),

          NewData1 = lists:keyreplace(in_powers, 1, Data, {in_powers, []}),
          NewData2 = lists:keyreplace(memory, 1, NewData1, {memory, New_memory}),
          Pid ! {reply, self(), ok},
          loop(NewData2)
      end





  after
    15000 ->
      io:format("Neuron~w timeout~n", [self()])
  end.


register_link(Pid_neuron_from, Pid_neuron_to, W) ->
  Pid_neuron_from ! {request, self(), {set_link_out, Pid_neuron_to, W}},
  Pid_neuron_to ! {request, self(), {set_link_in, Pid_neuron_from, W}},
  true.

gen_clean_memory(0) ->
  [];
gen_clean_memory(Length) ->
  [0] ++ gen_clean_memory(Length - 1).

calc_and_pulse_all(_, {_, _}, []) ->
  true;
calc_and_pulse_all(PidN, {PidFrom, Power}, [H | T]) ->
  {PidOut, W} = H,
  NewP = Power * W,
  PidOut ! {request, PidN, {pulse, PidFrom, NewP}},
  io:format("~w: Create pulse ~w to ~w~n", [self(), NewP, PidOut]),
  calc_and_pulse_all(PidN, {PidFrom, Power}, T).
