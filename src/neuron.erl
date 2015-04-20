%%%-------------------------------------------------------------------
%%% @author prokopiy
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%% Модуль реализует работу нейрона в нейросети дискретного времени
%%% Нейрон посылает сигнал на выход сразу после того как получит сигнал со всех входов
%%%
%%% @end
%%% Created : 13. Дек. 2014 21:57
%%%-------------------------------------------------------------------
-module(neuron).
-author("prokopiy").

%% API
-export([new/1, loop/1, pulse_to_neurons_list/2, print/1]).

new(Memory_size) ->
  N = [{power, 0}, {memory_size, Memory_size}, {in_links, []}, {out_links, []}, {num_active_links, 0}],
  spawn(neuron, loop, [N]).

pulse_to_neurons_list([], _) ->
  true;
pulse_to_neurons_list([N], [P]) ->
  N ! {pulse, self(), P};
pulse_to_neurons_list([H1 | T1], [H2 | T2]) ->
  H1 ! {pulse, self(), H2},
  pulse_to_neurons_list(T1, T2).


calc_and_pulse_all(PidN, {FromPid, Power}, []) ->
  true;
calc_and_pulse_all(PidN, {PidFrom, Power}, [H | T]) ->
  {PidOut, W} = H,
  NewP = Power * W,
  PidOut ! {request, PidN, {pulse, PidFrom, NewP}},
  io:format("Create pulse ~w to ~w~n", [NewP, PidOut]),
  calc_and_pulse_all(PidN, {PidFrom, Power}, T).

print(NeuronPid) ->
  NeuronPid ! {request, self(), print}.


loop(N) ->
  receive
    {reply, _, ok} ->
      loop(N);
    {request, Pid, print} ->
      io:format("Neuron~w ~w~n", [self(), N]),
      Pid ! {reply, self(), ok},
      loop(N);
    {request, Pid, stop} ->
      io:format("Neuron~w stopped~n", [self()]);
    {request, PidN, {set_link_out, W}} ->
      {out_links, Out} = lists:keyfind(out_links, 1, N),
      NewOut = lists:keystore(PidN, 1, Out, {PidN, W}),
      NewN = lists:keyreplace(out_links, 1, N, {out_links, NewOut}),
      loop(NewN);
    {request, PidN, {set_link_in, W}} ->
      {in_links, In} = lists:keyfind(in_links, 1, N),
      NewIn = lists:keystore(PidN, 1, In, {PidN, W}),
      NewN = lists:keyreplace(in_links, 1, N, {in_links, NewIn}),
      loop(NewN);
    {request, Pid, {pulse, From, Power}} ->
      Pid ! {reply, self(), ok},
      {power, P} = lists:keyfind(power, 1, N),
      NewP = P + Power,
      {in_links, In} = lists:keyfind(in_links, 1, N),
      L = length(In),
      {num_active_links, A} = lists:keyfind(num_active_links, 1, N),
      NewA = A + 1,
      if
        NewA < L ->
          NewN1 = lists:keyreplace(power, 1, N, {power, NewP}),
          NewN2 = lists:keyreplace(num_active_links, 1, NewN1, {num_active_links, NewA}),
          loop(NewN2);
        NewA >= L ->
          S = math:tanh(NewP),
          {out_links, Out} = lists:keyfind(out_links, 1, N),
          if
            Out == [] ->
              io:format("Neuron~w: send effect ~w to ~w~n", [self(), NewP, From]),
              From ! {request, self(), {effect, NewP}};
            Out /= [] ->
              true
          end,
          calc_and_pulse_all(self(), {From, S}, Out),
          NewN1 = lists:keyreplace(power, 1, N, {power, 0}),
          NewN2 = lists:keyreplace(num_active_links, 1, NewN1, {num_active_links, 0}),
          loop(NewN2)
      end

  after
    20000 ->
      io:format("Neuron~w timeout~n", [self()])
  end.