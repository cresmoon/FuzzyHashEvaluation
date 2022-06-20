include("scoredata.jl")

function usage()
    println("USAGE: julia runanalysis.jl <path_to_score_dir> <path_to_label_file>")
end

function main()
    if length(ARGS) < 2
        usage()
        return
    end

    score_dir_path = ARGS[1]
    label_file_path = ARGS[2]
    println("Label data: $label_file_path")

    num_mw_files = 10868
    is_similarity_score = true
    score_file_list = [("/sdhash_std_scores_1.txt", is_similarity_score, num_mw_files),
                       ("/sdhash_std_scores_2.txt", is_similarity_score, num_mw_files),
                       ("/ssdeep_std_scores.txt", is_similarity_score, num_mw_files),
                       ("/mrsh2_std_scores.txt", is_similarity_score, num_mw_files),
                       ("/tlsh_std_scores.txt", !is_similarity_score, num_mw_files - 8)]

    for score_file_tup in score_file_list
        score_file = score_file_tup[1]
        is_similarity = score_file_tup[2]
        num_points = score_file_tup[3]
        score_file_path = score_dir_path * score_file
        println("Analyzing $score_file_path (is_similarity=$is_similarity)")
        score_data = read_score_file(score_file_path, label_file_path, num_points, is_similarity)
        eval_score_data(score_data, 1)
    end
end

main()
