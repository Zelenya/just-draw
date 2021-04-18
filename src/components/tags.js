import * as React from "react"
import { Link } from "gatsby"

const Tags = ({ tags, tagSlugs }) => (
  <div className="tags">
    {tagSlugs &&
      tagSlugs.map((slug, i) => (
        <div className="tag" key={tags[i]}>
          <Link to={slug} >
            {tags[i]}
          </Link>
        </div>
      ))}
  </div>
)

export default Tags
