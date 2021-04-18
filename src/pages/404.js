import * as React from "react"
import { graphql } from "gatsby"

import Burrito from "../components/burrito"
import SEO from "../components/seo"

const NotFoundPage = ({ data, location }) => {
  const siteTitle = data.site.siteMetadata.title

  return (
    <Burrito location={location} title={siteTitle}>
      <SEO title="404: Not Found" />
      <div className="not-found-page">
        <h1>404: Not Found</h1>
        <p>I'm sorry if I removed an existing page. I have no idea what I'm doing</p>
       </div>
    </Burrito>
  )
}

export default NotFoundPage

export const pageQuery = graphql`
  query {
    site {
      siteMetadata {
        title
      }
    }
  }
`
