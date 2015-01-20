%%%-------------------------------------------------------------------
%%% @author prokopiy
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. Дек. 2014 21:57
%%%-------------------------------------------------------------------
-module(neuron).
-author("prokopiy").

%% API
-export([new/0, loop/1]).

new() ->
  N = [{power, 0}, {in, []}, {out, []}, {num_active_links, 0}],
  spawn(neuron, loop, [N]).


calc_and_pulse_all(PidN, {FromPid, Power}, []) ->
  true;
calc_and_pulse_all(PidN, {PidFrom, Power}, [H | T]) ->
  {PidOut, W} = H,
  NewP = Power * W,
  PidOut ! {request, PidN, {pulse, PidFrom, NewP}},
  io:format("Create pulse ~w to ~w~n", [NewP, PidOut]),
  calc_and_pulse_all(PidN, {PidFrom, Power}, T).



loop(N) ->
  receive
    {reply, _, ok} ->
      loop(N);
    {request, Pid, print} ->
      io:format("Neuron~w ~w~n", [self(), N]),
      Pid ! {reply, self(), ok},
      loop(N);
    {request, Pid, stop} ->
      io:format("Neuron~w stop~n", [self()]);
    {request, PidN, {set_link_out, W}} ->
      {out, Out} = lists:keyfind(out, 1, N),
      NewOut = lists:keystore(PidN, 1, Out, {PidN, W}),
      NewN = lists:keyreplace(out, 1, N, {out, NewOut}),
      loop(NewN);
    {request, PidN, {set_link_in, W}} ->
      {in, In} = lists:keyfind(in, 1, N),
      NewIn = lists:keystore(PidN, 1, In, {PidN, W}),
      NewN = lists:keyreplace(in, 1, N, {in, NewIn}),
      loop(NewN);
    {request, Pid, {pulse, From, Power}} ->
      Pid ! {reply, self(), ok},
      {power, P} = lists:keyfind(power, 1, N),
      NewP = P + Power,
      {in, In} = lists:keyfind(in, 1, N),
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
          {out, Out} = lists:keyfind(out, 1, N),
          if
            Out == [] ->
              io:format("Neuron~w: send ~w to ~w~n", [self(), S, From]),
              From ! {request, self(), {effect, S}};
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