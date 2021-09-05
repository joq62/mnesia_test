all:
#	service
	rm -rf ebin/* src;
	rm -rf src/*.beam *.beam  test_src/*.beam test_ebin;
	rm -rf  glurk logs *~ */*~  erl_cra*;
	echo Done
doc_gen:
	echo glurk not implemented
unit_test:
	rm -rf ebin/* src/*.beam *.beam test_src/*.beam test_ebin host_lgh_*;
	rm -rf  *~ */*~  erl_cra*;
	rm -rf *_specs *_config deployment *.log;
	mkdir test_ebin;
#	test application
	cp test_src/*.app test_ebin;
	erlc -o test_ebin test_src/*.erl;
	erl -pa test_ebin\
	    -setcookie etcd_test_cookie\
	    -sname etcd_test\
	    -mnesia dir etcd_mnesia\
	    -unit_test cookie etcd_test_cookie\
	    -unit_test cluster_id glurk\
	    -unit_test monitor_node etcd_test\
	    -run unit_test start_test test_src/test.config
