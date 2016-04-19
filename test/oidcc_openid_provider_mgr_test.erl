-module(oidcc_openid_provider_mgr_test).
-include_lib("eunit/include/eunit.hrl").

start_stop_test() ->
    {ok, Pid} = oidcc_openid_provider_mgr:start_link(),
    ok = oidcc_openid_provider_mgr:stop(),
    ok = test_util:wait_for_process_to_die(Pid, 100),
    ok.


simple_add_test() ->
    MyPid = self(),
    AddFun = fun(_Id) ->
                     {ok, MyPid}
             end,
    ok = meck:new(oidcc_openid_provider_sup),
    ok = meck:expect(oidcc_openid_provider_sup, add_openid_provider, AddFun),

    {ok, Pid} = oidcc_openid_provider_mgr:start_link(),
    {ok, Id, MyPid} = oidcc_openid_provider_mgr:add_openid_provider(),
    {ok, [{Id, MyPid}]} = oidcc_openid_provider_mgr:get_openid_provider_list(),
    ok = oidcc_openid_provider_mgr:stop(),
    ok = test_util:wait_for_process_to_die(Pid, 100),

    true = meck:validate(oidcc_openid_provider_sup),
    ok = meck:unload(oidcc_openid_provider_sup),
    ok.


id_add_test() ->
    MyPid = self(),
    AddFun = fun(_Id) ->
                     {ok, MyPid}
             end,
    Id = <<"123">>,
    ok = meck:new(oidcc_openid_provider_sup),
    ok = meck:expect(oidcc_openid_provider_sup, add_openid_provider, AddFun),

    {ok, Pid} = oidcc_openid_provider_mgr:start_link(),
    {ok, Id, MyPid} = oidcc_openid_provider_mgr:add_openid_provider(Id),
    {ok, [{Id, MyPid}]} = oidcc_openid_provider_mgr:get_openid_provider_list(),
    ok = oidcc_openid_provider_mgr:stop(),
    ok = test_util:wait_for_process_to_die(Pid, 100),

    true = meck:validate(oidcc_openid_provider_sup),
    ok = meck:unload(oidcc_openid_provider_sup),
    ok.


double_add_test() ->
    MyPid = self(),
    AddFun = fun(_Id) ->
                     {ok, MyPid}
             end,
    ok = meck:new(oidcc_openid_provider_sup),
    ok = meck:expect(oidcc_openid_provider_sup, add_openid_provider, AddFun),

    {ok, Pid} = oidcc_openid_provider_mgr:start_link(),
    {ok, Id, MyPid} = oidcc_openid_provider_mgr:add_openid_provider(),
    {error, id_already_used} = oidcc_openid_provider_mgr:add_openid_provider(Id),
    {ok, _Id, MyPid} = oidcc_openid_provider_mgr:add_openid_provider(undefined),
    ok = oidcc_openid_provider_mgr:stop(),
    ok = test_util:wait_for_process_to_die(Pid, 100),

    true = meck:validate(oidcc_openid_provider_sup),
    ok = meck:unload(oidcc_openid_provider_sup),
    ok.

multiple_add_test() ->
    NumberToAdd = 1000,
    MyPid = self(),
    AddFun = fun(_Id) ->
                     {ok, MyPid}
             end,
    ok = meck:new(oidcc_openid_provider_sup),
    ok = meck:expect(oidcc_openid_provider_sup, add_openid_provider, AddFun),
    {ok, Pid} = oidcc_openid_provider_mgr:start_link(),
    ok = add_provider(NumberToAdd),
    {ok, List} = oidcc_openid_provider_mgr:get_openid_provider_list(),
    NumberToAdd = length(List),
    ok = oidcc_openid_provider_mgr:stop(),
    ok = test_util:wait_for_process_to_die(Pid, 100),

    true = meck:validate(oidcc_openid_provider_sup),
    ok = meck:unload(oidcc_openid_provider_sup),
    ok.

add_provider(0) ->
    ok;
add_provider(Num) ->
    {ok, _Id, _Pid} = oidcc_openid_provider_mgr:add_openid_provider(),
    add_provider(Num-1).



lookup_test() ->
    MyPid = self(),
    AddFun = fun(_Id) ->
                     {ok, MyPid}
             end,
    ok = meck:new(oidcc_openid_provider_sup),
    ok = meck:expect(oidcc_openid_provider_sup, add_openid_provider, AddFun),

    {ok, Pid} = oidcc_openid_provider_mgr:start_link(),
    {ok, Id, MyPid} = oidcc_openid_provider_mgr:add_openid_provider(),
    {ok, MyPid} = oidcc_openid_provider_mgr:get_openid_provider(Id),
    ok = oidcc_openid_provider_mgr:stop(),
    ok = test_util:wait_for_process_to_die(Pid, 100),

    true = meck:validate(oidcc_openid_provider_sup),
    ok = meck:unload(oidcc_openid_provider_sup),
    ok.


bad_lookup_test() ->
    MyPid = self(),
    AddFun = fun(_Id) ->
                     {ok, MyPid}
             end,
    Id = <<"some random Id">>,
    ok = meck:new(oidcc_openid_provider_sup),
    ok = meck:expect(oidcc_openid_provider_sup, add_openid_provider, AddFun),

    {ok, Pid} = oidcc_openid_provider_mgr:start_link(),
    {error, not_found} = oidcc_openid_provider_mgr:get_openid_provider(Id),
    ok = oidcc_openid_provider_mgr:stop(),
    ok = test_util:wait_for_process_to_die(Pid, 100),

    true = meck:validate(oidcc_openid_provider_sup),
    ok = meck:unload(oidcc_openid_provider_sup),
    ok.


garbage_test() ->
    {ok, Pid} = oidcc_openid_provider_mgr:start_link(),
    ignored = gen_server:call(Pid,unsupported_glibberish),
    ok = gen_server:cast(Pid,unsupported_glibberish),
    Pid ! some_unsupported_message,
    ok = oidcc_openid_provider_mgr:stop(),
    ok = test_util:wait_for_process_to_die(Pid, 100),
    ok.
