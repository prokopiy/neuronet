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
-export([new/0, new/1, loop/1, register_link/3, print/1, stop/1, pulse/2, print/1]).
% -export([new/1, loop/1, call/2, print_message/0, stop_message/0, set_link_out_message/2, set_link_in_message/2, register_link/3, new/0]).


new() ->
  new(0).

new(Memory_size) ->
  Data = #{
    in_powers => #{},
    memory => lists:duplicate(Memory_size, 0),
    in_links => #{},
    out_links => #{},
    errors => #{},
%%     num_active_links => 0
    last_out => 0.0
  },
  spawn(neuron, loop, [Data]).


call(Pid, Message) ->
  Pid ! {request, self(), Message},
  receive
    {reply, Pid, Reply} -> Reply
  end.


print(Neuron_pid) when is_pid(Neuron_pid) ->
%%   Neuron_pid ! {request, self(), print};
  call(Neuron_pid, print);
print([]) ->
  true;
print([H | T]) ->
  print(H),
  print(T).

stop(Neuron_pid) ->
  call(Neuron_pid, stop).


register_link(Pid_neuron_from, Pid_neuron_to, W) when is_pid(Pid_neuron_from), is_pid(Pid_neuron_to), is_number(W) ->
  Pid_neuron_from ! {request, self(), {set_link_out, Pid_neuron_to, W}},
  Pid_neuron_to ! {request, self(), {set_link_in, Pid_neuron_from, W}},
  true;
register_link(Pid_neuron_from, List_neurons_to, W) when is_pid(Pid_neuron_from), is_list(List_neurons_to), is_number(W) ->
  lists:foreach(fun(P) -> register_link(Pid_neuron_from, P, W) end, List_neurons_to).



pulse(Neuron_pid, Value) when is_pid(Neuron_pid) ->
  Neuron_pid ! {request, self(), {pulse, self(), Value}}.

get_last_out(Neuron_pid) ->
%%   io:format("~w get_last_out ~w~n", [self(), Neuron_pid]),
  Neuron_pid ! {request, self(), get_last_out},
  receive
    {reply, Neuron_pid, {ok, {last_out, Reply}}} -> Reply
  end.


loop(Data) ->
  receive
    {reply, _, ok} ->
      loop(Data);
    {reply, _, {confirm_back_error, ok}} ->
      loop(Data);
    {request, Pid, print} ->
      io:format("Neuron~w = ~w~n", [self(), Data]),
      Pid ! {reply, self(), ok},
      loop(Data);
    {request, Pid, stop} ->
      io:format("Neuron~w stopped~n", [self()]);
    {request, Pid, get_last_out} ->
      Pid ! {reply, self(), {ok, {last_out, maps:get(last_out, Data)}}},
      loop(Data);
    {request, Pid, {set_link_out, Output_neuron_pid, W}} ->
      Current_out_links = maps:get(out_links, Data),
      New_out_links = maps:put(Output_neuron_pid, W, Current_out_links),
      NewData = Data#{out_links := New_out_links},
      loop(NewData);
    {request, Pid, {set_link_in, Input_neuron_pid, W}} ->
      Current_in_links = maps:get(in_links, Data),
      New_in_links = maps:put(Input_neuron_pid, W, Current_in_links),
      NewData = Data#{in_links := New_in_links},
      loop(NewData);
    {request, Pid, {pulse, From, Power}} ->
      Current_in_powers = maps:get(in_powers, Data),
      New_in_powers = maps:put(Pid, Power, Current_in_powers),
      New_in_powers_length = maps:size(New_in_powers),
      Current_in_links = maps:get(in_links, Data),
      Current_in_links_length = maps:size(Current_in_links),
      if
        New_in_powers_length < Current_in_links_length ->
          NewData = Data#{in_powers := New_in_powers},
          Pid ! {reply, self(), ok},
          loop(NewData);
        New_in_powers_length >= Current_in_links_length ->
          Sum_in_powers = maps:fold(fun(_, V, Acc) -> Acc + V end, 0, New_in_powers),
          Current_memory = maps:get(memory, Data),
          New_memory1 = Current_memory ++ [math:tanh(Sum_in_powers)],
          [Last_power | New_memory] = New_memory1,
          Out = maps:get(out_links, Data),
          case maps:size(Out) of
            0 ->
%%               io:format("Neuron~w: send effect ~w to ~w~n", [self(), Last_power, From]),
              From ! {reply, self(), {effect, Last_power}};
            _Other ->
              true
          end,
          calc_and_pulse_all(self(), {From, Last_power}, Out),
          NewData1 = Data#{in_powers := #{}},
          NewData2 = NewData1#{memory := New_memory},
          NewData3 = NewData2#{last_out := Last_power},
          Pid ! {reply, self(), ok},
          loop(NewData3)
      end;

    {request, Pid, {back_error, Value}} ->
      Current_in_links = maps:get(in_links, Data),
      Current_errors = maps:get(errors, Data),
      New_errors = maps:put(Pid, Value, Current_errors),
      New_errors_length = maps:size(New_errors),
      Current_out_links = maps:get(out_links, Data),
      Current_out_links_length = maps:size(Current_out_links),
      if
        New_errors_length < Current_out_links_length ->
          NewData = Data#{errors := New_errors},
          loop(NewData);
        New_errors_length >= Current_out_links_length ->
          Sum_errors = maps:fold(fun(_, V, Acc) -> Acc + V end, 0, New_errors),
          Fun1 = fun(K, W, AccIn) when is_pid(K) ->
            K ! {request, self(), {back_error, Sum_errors * W}},
            AccIn
          end,
          maps:fold(Fun1, 0, Current_in_links),
          Fun2 = fun(K, W, AccIn) when is_pid(K) ->
            X = get_last_out(K),
            NewW = W + Sum_errors * ((1 + X) * (1 - X)) + abs(Sum_errors) * (0.5 - random:uniform()),
            K ! {request, self(), {set_link_out, self(), NewW}},
            maps:put(K, NewW, AccIn)
          end,
          New_in_links = maps:fold(Fun2, #{}, Current_in_links),
          NewData1 = Data#{errors := #{}},
          NewData2 = NewData1#{in_links := New_in_links},
          Pid ! {reply, self(), {confirm_back_error, ok}},
          loop(NewData2)
      end

  after
    15000 ->
%%       io:format("Neuron~w timeout~n", [self()])
      true
  end.



calc_and_pulse_all(PidN, {PidFrom, Power}, Map) ->
  Fun = fun(K, W, Acc) when is_pid(K) ->
    K ! {request, PidN, {pulse, PidFrom, Power * W}},
%%     io:format("~w: Create pulse ~w to ~w~n", [self(), Power * W, K]),
    Acc
  end,
  maps:fold(Fun, 0, Map).