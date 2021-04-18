import * as React from "react"
import { Link, graphql } from "gatsby"

import Burrito from "../components/burrito"
import SEO from "../components/seo"

const BlogIndex = ({ data, location }) => {
  const siteTitle = data.site.siteMetadata?.title || `Title`
  const exercises = data.exercises.group.map(e => e.fieldValue);
  const [tagOptions] = React.useState(data.tags.group.map(tag =>[tag.fieldValue, `/tag/${tag.fieldValue}`]));
  const random = exercises[Math.floor(Math.random() * exercises.length)];
  const [selected, setSelected] = React.useState("/");
  console.log(selected)
  return (
    <Burrito location={location} title={siteTitle}>
      <SEO title="Just draw"/>
      <div className="just-draw">
        <div className="call-to-action">
          <h3>I want to practice </h3>
          <select
            className="tag-dropdown"
            value={selected}
            onChange={e => setSelected(e.currentTarget.value)}
            >
            <option value="/">Select a tag:</option>
            {tagOptions.map(tag => (
              <option key={tag[0]} value={tag[1]}>
                {tag[0]}
              </option>
            ))}
          </select>
        </div>
        <div className="buttons">
          <Link className="btn" to={random} itemProp="url" >
            <span>I'm feeling lucky</span>
          </Link>
          <Link className="btn" to={selected} disabled={selected==="/"} itemProp="url" >
            <span>Practice</span>
          </Link>
        </div>
      </div>
    </Burrito>
  )
}

export default BlogIndex

export const pageQuery = graphql`
  {
    site {
      siteMetadata {
        title
      }
    }
    tags: allMarkdownRemark {
      group(field: frontmatter___tags) {
        fieldValue
      }
    }
    exercises: allMarkdownRemark {
      group(field: fields___slug) {
        fieldValue
      }
    }
  }
`
