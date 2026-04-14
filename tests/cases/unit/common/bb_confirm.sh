function test_bb_confirm {
	echo "y" | bb_confirm
	asserteq $? 1
	echo "Y" | bb_confirm
	asserteq $? 1
	echo "n" | bb_confirm
	asserteq $? 0
	echo "N" | bb_confirm
	asserteq $? 0
	echo "invalid" | bb_confirm
	asserteq $? 0
	prompt=$(echo "y" | bb_confirm "question ?")
	asserteq $? 1
	asserteq "${prompt}" "question ? (y/n) "
	prompt=$(echo "Y" | bb_confirm "question ?")
	asserteq $? 1
	asserteq "${prompt}" "question ? (y/n) "
	prompt=$(echo "n" | bb_confirm "question ?")
	asserteq $? 0
	asserteq "${prompt}" "question ? (y/n) "
	prompt=$(echo "N" | bb_confirm "question ?")
	asserteq $? 0
	asserteq "${prompt}" "question ? (y/n) "
	prompt=$(echo "invalid" | bb_confirm "question ?")
	asserteq $? 0
	asserteq "${prompt}" "question ? (y/n) "

}
bb_declare_test test_bb_confirm
