import CSV

struct ScoreData
    name2idx::Dict{String, Int}
    name::Array{String, 1}
    score::Array{Int16, 2}
    label::Array{Int8, 1}
end

function read_score_file(file_path::AbstractString,
                         label_path::AbstractString,
                         num_points::Int, is_score_similarity::Bool)
    name2idx = Dict{String, Int}()
    name = Array{String, 1}(undef, num_points)
    score_matrix = ones(Int16, num_points, num_points) * (-1)
    score_rows = CSV.Rows(file_path, header=["f1", "f2", "s"])
    point_count = 1
    for r in score_rows
        f1 = split(r.f1, '.')[1]
        f2 = split(r.f2, '.')[1]
        if !haskey(name2idx, f1)
            name2idx[f1] = point_count
            name[point_count] = f1
            point_count += 1
        end
        if !haskey(name2idx, f2)
            name2idx[f2] = point_count
            name[point_count] = f2
            point_count += 1
        end
        i1, i2 = name2idx[f1], name2idx[f2]
        score = parse(Int16, r.s)
        if is_score_similarity
            # convert score to distance if it's a similarity score
            score = 100 - score
        end
        if i1 == i2
            if score != 0
                println("ERROR: distance score between same files not 0")
            end
            # same point, skip the score
            continue
        end
        if score_matrix[i1, i2] < 0
            score_matrix[i1, i2] = score_matrix[i2, i1] = score
        elseif score_matrix[i1, i2] != score
            println("ERROR: Score mismatched! $(score_matrix[i1, i2]) vs. $score")
        end
    end
    if point_count - 1 != num_points
        println("ERROR: Num points mismatched! $num_points expected vs. $(point_count-1) in file")
    end

    # now read in labels
    label_vector = zeros(Int8, num_points)
    label_count = 1
    for label_row in CSV.Rows(label_path)
        if !haskey(name2idx, label_row.Id)
            # println("No score for $(label_row.Id) - skipping!")
            continue
        end
        idx = name2idx[label_row.Id]
        label_vector[idx] = parse(Int8, label_row.Class)
        label_count += 1
    end
    if label_count - 1 != num_points
        println("ERROR: Num labels mismatched! $num_points expected vs. $(label_count-1) in file")
    end

    return ScoreData(name2idx, name, score_matrix, label_vector)
end

function find_non_negative_min_set(vec::T) where T <: AbstractArray
    max_val = nothing
    min_val = nothing
    if isempty(vec)
        return (max_val, min_val, vec)
    end
    itemT = typeof(vec[1])
    min_set = itemT[]
    for (i, v) in enumerate(vec)
        if v < 0
            continue
        end
        if isnothing(max_val)
            max_val = v
            min_val = v
        end
        if v > max_val
            max_val = v
        end
        if v < min_val
            min_val = v
            min_set = itemT[]  # reset min set
            push!(min_set, i)
        elseif v == min_val
            push!(min_set, i)
        end
    end
    if max_val == min_val
        return (max_val, min_val, itemT[])  # return empty min set
    end
    return (max_val, min_val, min_set)
end

function eval_score_data(score_data::ScoreData, k:: Int)
    total_m = 0
    matched_m = 0
    for m in score_data.name
        m_idx = score_data.name2idx[m]
        m_label = score_data.label[m_idx]
        if (m_label < 1) || (m_label > 9)
            println("ERROR: Unexpected label for $m: $m_label")
        end
        m_score = score_data.score[m_idx, :]
        score_max, score_min, score_min_idx_set = find_non_negative_min_set(m_score)
        if score_min < 0
            println("ERROR: negative min score of $score_min")
            continue
        end
        total_m += 1
        for score_min_idx in score_min_idx_set
            nearest_m = score_data.name[score_min_idx]
            nearest_label = score_data.label[score_min_idx]
            if nearest_label == m_label
                matched_m += 1
                break
            end
        end
    end
    accuracy = matched_m / total_m * 100
    println("$total_m $matched_m $accuracy")
end
