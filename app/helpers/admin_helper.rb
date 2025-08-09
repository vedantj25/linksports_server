module AdminHelper
  # Generic sort link builder preserving current params and path
  def sort_link(column, label)
    current_sort = params[:sort]
    current_dir = params[:dir] == "desc" ? "desc" : "asc"
    dir = (current_sort == column && current_dir == "asc") ? "desc" : "asc"
    icon = if current_sort == column
             current_dir == "asc" ? "fa-solid fa-arrow-up-a-z" : "fa-solid fa-arrow-down-z-a"
    else
             "fa-solid fa-arrow-up-arrow-down"
    end
    url = url_for(request.params.merge(sort: column, dir: dir, only_path: true))
    link_to url, class: "text-decoration-none" do
      raw("#{label} <i class='#{icon} ms-1'></i>")
    end
  end
end
