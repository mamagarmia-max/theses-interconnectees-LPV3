all:
	g++ -O3 -march=native -fopenmp -o skernel_v3 skernel_v3_cpp.cpp

run:
	./skernel_v3

plot:
	python3 plot_results.py
