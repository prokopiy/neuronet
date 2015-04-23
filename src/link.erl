%%%-------------------------------------------------------------------
%%% @author prokopiy
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. Дек. 2014 0:01
%%%-------------------------------------------------------------------
-module(link).
-author("prokopiy").

%% API
-export([register_neuron_to_neuron/3, register_neuron_to_neuron_list/3, register_many_to_many/3, register_rnd/2]).
%%

register_neuron_to_neuron(Pid_neuron_from, Pid_neuron_to, W) ->
  neuron:register_link(Pid_neuron_from, Pid_neuron_to, W).
%%   neuron:call(Pid_neuron_from, neuron:set_link_out_message(Pid_neuron_to, W)),
%%   neuron:call(Pid_neuron_to, neuron:set_link_in_message(Pid_neuron_from, W)).
%%   PidN1 ! {request, PidN2, {set_link_out, W}},
%%   PidN2 ! {request, PidN1, {set_link_in, W}}.


register_neuron_to_neuron_list(_, [], _) ->
  true;
register_neuron_to_neuron_list(PidN, [H | T], [WH | WT]) ->
  register_neuron_to_neuron(PidN, H, WH),
  register_neuron_to_neuron_list(PidN, T, WT).


register_many_to_many([], _, _) ->
  true;
register_many_to_many([H], L, W) ->
  register_neuron_to_neuron_list(H, L, W);
register_many_to_many([H1 | T1], L, [WH | WT]) ->
  register_neuron_to_neuron_list(H1, L, WH),
  register_many_to_many(T1, L, WT).


register_rnd(L1, L2) ->
  W = lists:map(fun(X) -> lists:map(fun(Y) -> random:uniform() end, L2) end, L1),
  register_many_to_many(L1, L2, W).

